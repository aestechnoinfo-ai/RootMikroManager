import 'package:flutter/material.dart';

class BridgeVlanPortSelector extends StatelessWidget {
  final String title;
  final List<String> choices;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  const BridgeVlanPortSelector({
    super.key,
    required this.title,
    required this.choices,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: Text(title),
      subtitle: Text(
        selected.isEmpty ? 'Aucune sélection' : selected.join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        for (final item in choices)
          CheckboxListTile(
            value: selected.contains(item),
            title: Text(item),
            onChanged: (v) {
              final next = <String>{...selected};
              if (v == true)
                next.add(item);
              else
                next.remove(item);
              onChanged(next);
            },
          ),
      ],
    ),
  );
}
