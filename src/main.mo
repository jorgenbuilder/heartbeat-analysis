import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

import Canistergeek "mo:canistergeek/canistergeek";


actor Heartbeat {

    private stable var _canistergeekMonitorUD: ? Canistergeek.UpgradeData = null;
    private stable var _canistergeekLoggerUD: ? Canistergeek.LoggerUpgradeData = null;

    system func preupgrade() {
        _canistergeekMonitorUD := ? canistergeekMonitor.preupgrade();
        _canistergeekLoggerUD := ? canistergeekLogger.preupgrade();
    };

    system func postupgrade() {
        canistergeekMonitor.postupgrade(_canistergeekMonitorUD);
        _canistergeekMonitorUD := null;
        canistergeekLogger.postupgrade(_canistergeekLoggerUD);
        _canistergeekLoggerUD := null;
    };

    system func heartbeat() : async () {
        // Once an hour, basically.
        let t = Time.now();
        if (t % (60 * 60_000_000_000) < 750_000_000) {
            _captureMetrics();
            _log("tick");
        }
    };

    ///////////////////
    // Canistergeek //
    /////////////////


    // Metrics

    private let canistergeekMonitor = Canistergeek.Monitor();

    /**
    * Returns collected data based on passed parameters.
    * Called from browser.
    */
    public query ({caller}) func getCanisterMetrics(parameters: Canistergeek.GetMetricsParameters): async ?Canistergeek.CanisterMetrics {
        canistergeekMonitor.getMetrics(parameters);
    };

    /**
    * Force collecting the data at current time.
    * Called from browser or any canister "update" method.
    */
    public shared ({caller}) func collectCanisterMetrics(): async () {
        _captureMetrics();
        canistergeekMonitor.collectMetrics();
    };

    // This needs to be places in every update call.
    private func _captureMetrics () : () {
        canistergeekMonitor.collectMetrics();
    };

    // Logging

    private let canistergeekLogger = Canistergeek.Logger();

    /**
    * Returns collected log messages based on passed parameters.
    * Called from browser.
    */
    public query ({caller}) func getCanisterLog(request: ?Canistergeek.CanisterLogRequest) : async ?Canistergeek.CanisterLogResponse {
        canistergeekLogger.getLog(request);
    };

    private func _log (
        message : Text,
    ) : () {
        Debug.print(message);
        canistergeekLogger.logMessage(
            message
        );
    };

}