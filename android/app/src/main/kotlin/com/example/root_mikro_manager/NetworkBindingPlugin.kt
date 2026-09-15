package com.example.root_mikro_manager

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.Socket
import java.net.SocketTimeoutException
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class NetworkBindingPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    private val executor = Executors.newCachedThreadPool()
    private lateinit var channel: MethodChannel
    private lateinit var mndpEvents: EventChannel
    private val mainHandler = Handler(Looper.getMainLooper())
    private var activeDiscovery: AtomicBoolean? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, "root_mikro_manager/network_binding")
        channel.setMethodCallHandler(this)
        mndpEvents = EventChannel(messenger, "root_mikro_manager/network_binding/mndp")
        mndpEvents.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                activeDiscovery?.set(false)
                val running = AtomicBoolean(true)
                activeDiscovery = running
                val duration = ((arguments as? Map<*, *>)?.get("durationMs") as? Number)
                    ?.toInt() ?: 15000
                executor.execute {
                    try {
                        discoverMndp(duration, running) { row ->
                            mainHandler.post { if (running.get()) events.success(row) }
                        }
                        mainHandler.post { if (running.getAndSet(false)) events.endOfStream() }
                    } catch (error: Exception) {
                        mainHandler.post {
                            if (running.getAndSet(false)) {
                                events.error("mndp_failed", error.message, null)
                            }
                        }
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                activeDiscovery?.set(false)
                activeDiscovery = null
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "networkState" -> result.success(networkState())
            "probeTcp" -> executor.execute {
                val host = call.argument<String>("host").orEmpty()
                val port = call.argument<Int>("port") ?: 0
                val timeout = call.argument<Int>("timeoutMs") ?: 15000
                val bindVpn = call.argument<Boolean>("bindVpn") ?: false
                try {
                    result.success(probeTcp(host, port, timeout, bindVpn))
                } catch (error: Exception) {
                    result.error("probe_failed", error.message, null)
                }
            }
            "discoverMndp" -> executor.execute {
                val duration = call.argument<Int>("durationMs") ?: 15000
                try {
                    result.success(discoverMndp(duration))
                } catch (error: Exception) {
                    result.error("mndp_failed", error.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun connectivityManager() =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private fun vpnNetwork(): Network? = connectivityManager().allNetworks.firstOrNull { network ->
        connectivityManager().getNetworkCapabilities(network)
            ?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
    }

    private fun networkState(): Map<String, Any> {
        val manager = connectivityManager()
        val active = manager.activeNetwork
        val capabilities = active?.let(manager::getNetworkCapabilities)
        val interfaces = NetworkInterface.getNetworkInterfaces().toList()
            .filter { it.isUp }.map { it.name }
        return mapOf(
            "wifi" to (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true),
            "cellular" to (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true),
            "vpn" to (vpnNetwork() != null),
            "interfaces" to interfaces,
            "vpnInterface" to (interfaces.firstOrNull { it.startsWith("tun") || it.startsWith("wg") } ?: "")
        )
    }

    private fun probeTcp(host: String, port: Int, timeoutMs: Int, bindVpn: Boolean): Boolean {
        require(host.isNotBlank() && port in 1..65535)
        val socket = Socket()
        return try {
            if (bindVpn) vpnNetwork()?.bindSocket(socket)
            socket.connect(InetSocketAddress(host, port), timeoutMs.coerceIn(1000, 20000))
            true
        } finally {
            try { socket.close() } catch (_: Exception) { }
        }
    }

    private fun discoverMndp(durationMs: Int): List<Map<String, String>> {
        val rows = mutableListOf<Map<String, String>>()
        discoverMndp(durationMs, AtomicBoolean(true)) { rows.add(it) }
        return rows
    }

    private fun discoverMndp(
        durationMs: Int,
        running: AtomicBoolean,
        onDevice: (Map<String, String>) -> Unit
    ) {
        val wifi = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val lock = wifi.createMulticastLock("RootMikroManager-MNDP").apply {
            setReferenceCounted(false)
            acquire()
        }
        val socket = DatagramSocket(null)
        val found = linkedMapOf<String, Map<String, String>>()
        try {
            socket.reuseAddress = true
            socket.broadcast = true
            socket.bind(InetSocketAddress(InetAddress.getByName("0.0.0.0"), 5678))
            socket.soTimeout = 300
            val request = DatagramPacket(ByteArray(4), 4, InetAddress.getByName("255.255.255.255"), 5678)
            socket.send(request)
            val deadline = System.currentTimeMillis() + durationMs.coerceIn(1000, 20000)
            while (running.get() && System.currentTimeMillis() < deadline) {
                val buffer = ByteArray(8192)
                val packet = DatagramPacket(buffer, buffer.size)
                try {
                    socket.receive(packet)
                    val row = parseMndp(packet.data, packet.length).toMutableMap()
                    row["raw"] = android.util.Base64.encodeToString(
                        packet.data.copyOf(packet.length), android.util.Base64.NO_WRAP)
                    if (row["address"].isNullOrBlank()) {
                        val source = packet.address.hostAddress.orEmpty()
                        if (!source.contains(':')) row["address"] = source
                    }
                    val key = row["mac-address"].orEmpty()
                    if (key.isNotEmpty() && !found.containsKey(key)) {
                        found[key] = row
                        onDevice(row)
                    }
                } catch (_: SocketTimeoutException) { }
            }
        } finally {
            socket.close()
            if (lock.isHeld) lock.release()
        }
    }

    private fun parseMndp(data: ByteArray, length: Int): Map<String, String> {
        val fields = mutableMapOf<String, String>("protocols" to "MNDP")
        var offset = 4
        while (offset + 4 <= length) {
            val type = ((data[offset].toInt() and 0xff) shl 8) or (data[offset + 1].toInt() and 0xff)
            val size = ((data[offset + 2].toInt() and 0xff) shl 8) or (data[offset + 3].toInt() and 0xff)
            offset += 4
            if (size < 0 || offset + size > length) break
            val bytes = data.copyOfRange(offset, offset + size)
            val text = bytes.toString(Charsets.UTF_8).trimEnd('\u0000')
            when (type) {
                1 -> if (size >= 6) fields["mac-address"] = bytes.take(6).joinToString(":") { "%02X".format(it) }
                5 -> fields["identity"] = text
                7 -> fields["version"] = text
                8 -> fields["platform"] = text
                12 -> fields["board"] = text
                16 -> fields["interface"] = text
                17 -> if (size == 4) {
                    fields["address"] = bytes.joinToString(".") { (it.toInt() and 0xff).toString() }
                }
            }
            offset += size
        }
        return fields
    }
}
