import 'mikhmon_time_parser.dart';

enum HotspotExpirationMode {
  none('0', 'None'),
  remove('rem', 'Remove'),
  notice('ntf', 'Notice'),
  removeAndRecord('remc', 'Remove & Record'),
  noticeAndRecord('ntfc', 'Notice & Record');

  final String code;
  final String label;

  const HotspotExpirationMode(this.code, this.label);

  static HotspotExpirationMode fromCode(String? value) {
    return HotspotExpirationMode.values.firstWhere(
      (mode) => mode.code == value,
      orElse: () => HotspotExpirationMode.none,
    );
  }
}

class HotspotProfileConfig {
  final String? id;
  final String originalName;
  final String name;
  final String addressPool;
  final int sharedUsers;
  final String rateLimit;
  final HotspotExpirationMode expirationMode;
  final String validity;
  final String gracePeriod;
  final String price;
  final String sellingPrice;
  final bool lockUser;
  final String parentQueue;

  const HotspotProfileConfig({
    this.id,
    this.originalName = '',
    required this.name,
    this.addressPool = 'none',
    this.sharedUsers = 1,
    this.rateLimit = '',
    this.expirationMode = HotspotExpirationMode.none,
    this.validity = '',
    this.gracePeriod = '5m',
    this.price = '0',
    this.sellingPrice = '0',
    this.lockUser = false,
    this.parentQueue = 'none',
  });

  factory HotspotProfileConfig.fromRouterOs(Map<String, String> row) {
    final metadata = RootMikroManagerProfileScriptCodec.parseOnLogin(
      row['on-login'] ?? '',
    );

    return HotspotProfileConfig(
      id: row['.id'],
      originalName: row['name'] ?? '',
      name: row['name'] ?? '',
      addressPool: _none(row['address-pool']),
      sharedUsers: int.tryParse(row['shared-users'] ?? '') ?? 1,
      rateLimit: row['rate-limit'] ?? '',
      expirationMode: HotspotExpirationMode.fromCode(metadata.expirationMode),
      validity: metadata.validity,
      gracePeriod: metadata.gracePeriod,
      price: metadata.price,
      sellingPrice: metadata.sellingPrice,
      lockUser: metadata.lockUser,
      parentQueue: _none(row['parent-queue']),
    );
  }

  static String _none(String? value) =>
      value == null || value.trim().isEmpty ? 'none' : value.trim();
}

class RootMikroManagerProfileMetadata {
  final String expirationMode;
  final String price;
  final String validity;
  final String sellingPrice;
  final bool lockUser;
  final String gracePeriod;

  const RootMikroManagerProfileMetadata({
    this.expirationMode = '0',
    this.price = '0',
    this.validity = '',
    this.sellingPrice = '0',
    this.lockUser = false,
    this.gracePeriod = '5m',
  });
}

class RootMikroManagerProfileScriptCodec {
  static RootMikroManagerProfileMetadata parseOnLogin(String script) {
    final match = RegExp(
      r':put\s*\(\s*"?,([^,]*),([^,]*),([^,]*),([^,]*),,([^,]*),"?\s*\)',
      caseSensitive: false,
    ).firstMatch(script);

    if (match == null) {
      return const RootMikroManagerProfileMetadata();
    }

    final lockToken = (match.group(5) ?? '').trim();

    return RootMikroManagerProfileMetadata(
      expirationMode: (match.group(1) ?? '0').trim(),
      price: _zero(match.group(2)),
      validity: (match.group(3) ?? '').trim(),
      sellingPrice: _zero(match.group(4)),
      lockUser:
          lockToken.isNotEmpty &&
          lockToken.toLowerCase() != 'disable' &&
          lockToken.toLowerCase() != 'no',
    );
  }

  static String buildOnLogin(HotspotProfileConfig config) {
    final mode = config.expirationMode.code;
    final price = _zero(config.price);
    final sellingPrice = _zero(config.sellingPrice);
    final validity = MikhmonTimeParser.normalize(config.validity);

    final lockScript = config.lockUser
        ? '; [:local mac \$"mac-address"; /ip hotspot user set '
              'mac-address=\$mac [find where name=\$user]]'
        : '';

    if (config.expirationMode == HotspotExpirationMode.none) {
      if (price == '0' && sellingPrice == '0' && !config.lockUser) {
        return '';
      }

      return ':put (",,$price,,$sellingPrice,,'
          '${config.lockUser ? 'Enable' : 'Disable'},")$lockScript';
    }

    final record =
        '; :local mac \$"mac-address"; '
        ':local time [/system clock get time ]; '
        '/system script add '
        'name="\$date-|-\$time-|-\$user-|-$price-|-\$address-|-\$mac-|-'
        '$validity-|-${config.name}-|-\$comment" '
        'owner="\$month\$year" source="\$date" '
        'comment="RootMikroManager"';

    var script =
        ':put (",$mode,$price,$validity,$sellingPrice,,'
        '${config.lockUser ? 'Enable' : 'Disable'},"); '
        '{:local comment [ /ip hotspot user get '
        '[/ip hotspot user find where name="\$user"] comment]; '
        ':local ucode [:pick \$comment 0 2]; '
        ':if (\$ucode = "vc" or \$ucode = "up" or \$comment = "") do={ '
        ':local date [ /system clock get date ]; '
        ':local year [ :pick \$date 0 4 ]; '
        ':local month [ :pick \$date 5 7 ]; '
        ':if ([:len [/system scheduler find where name="\$user"]] = 0) do={ '
        ':local expiryEvent (":local targetUser \\"" . \$user . "\\"; '
        ':local previousComment [/ip hotspot user get [find where name=\\\$targetUser] comment]; '
        '/ip hotspot active remove [find where user=\\\$targetUser]; '
        '/ip hotspot user set disabled=yes comment=(\\"expre=1;\\" . \\\$previousComment) '
        '[find where name=\\\$targetUser]; '
        '/system scheduler remove [find where name=\\\$targetUser]"); '
        '/system scheduler add name="\$user" disabled=no '
        'start-date=\$date interval="$validity" on-event=\$expiryEvent; }';

    if (config.expirationMode == HotspotExpirationMode.removeAndRecord ||
        config.expirationMode == HotspotExpirationMode.noticeAndRecord) {
      script += record;
    }

    script += lockScript;
    script += '}}';

    return script;
  }

  static String buildBackgroundService(HotspotProfileConfig config) {
    final action = switch (config.expirationMode) {
      HotspotExpirationMode.remove ||
      HotspotExpirationMode.removeAndRecord => 'remove \$userId',
      HotspotExpirationMode.notice ||
      HotspotExpirationMode.noticeAndRecord => 'set limit-uptime=1s \$userId',
      HotspotExpirationMode.none => '',
    };

    if (action.isEmpty) return '';

    return ':local dateint do={'
        ':local montharray ("01","02","03","04","05","06","07","08","09","10","11","12");'
        ':local days [:pick \$d 8 10];'
        ':local month [:pick \$d 5 7];'
        ':local year [:pick \$d 0 4];'
        ':local monthint ([:find \$montharray \$month]);'
        ':local month (\$monthint + 1);'
        ':if ([:len \$month] = 1) do={'
        ':local zero ("0");'
        ':return [:tonum ("\$year\$zero\$month\$days")];'
        '} else={:return [:tonum ("\$year\$month\$days")];}};'
        ':local timeint do={'
        ':local hours [:pick \$t 0 2];'
        ':local minutes [:pick \$t 3 5];'
        ':return (\$hours * 60 + \$minutes);};'
        ':local date [/system clock get date];'
        ':local time [/system clock get time];'
        ':local today [\$dateint d=\$date];'
        ':local curtime [\$timeint t=\$time];'
        ':foreach userId in [/ip hotspot user find where profile="${config.name}"] do={'
        ':local comment [/ip hotspot user get \$userId comment];'
        ':local name [/ip hotspot user get \$userId name];'
        ':local gettime [:pick \$comment 11 19];'
        ':if ([:pick \$comment 4] = "-" and [:pick \$comment 7] = "-") do={'
        ':local expd [\$dateint d=\$comment];'
        ':local expt [\$timeint t=\$gettime];'
        ':if ((\$expd < \$today and \$expt < \$curtime) or '
        '(\$expd < \$today and \$expt > \$curtime) or '
        '(\$expd = \$today and \$expt < \$curtime)) do={'
        '[/ip hotspot cookie remove [find where user=\$name]];'
        '[/ip hotspot active remove [find where user=\$name]];'
        '[/ip hotspot user $action];'
        '}}}';
  }

  static String _zero(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? '0' : text;
  }
}
