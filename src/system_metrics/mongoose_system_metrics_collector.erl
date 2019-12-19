-module(mongoose_system_metrics_collector).

-type report_struct() :: 
    #{
        report_name := term(),
        key := term(),
        value := term()
    }.

-export_type([report_struct/0]).

-export([collect/0]).

collect() ->
    ReportResults = [ get_reports(RGetter) || RGetter <- report_getters()],
    lists:flatten(ReportResults).

-spec get_reports(fun(() -> [report_struct()])) -> [report_struct()].
get_reports(Fun) ->
    Fun().

-spec report_getters() -> [fun(() -> [report_struct()])].
report_getters() ->
    [
        fun get_hosts_count/0,
        fun get_modules/0,
        fun get_uptime/0,
        fun get_cluster_size/0
%%        fun get_loglevel/0
    ].

get_hosts_count() ->
    Hosts = ejabberd_config:get_global_option(hosts),
    NumberOfHosts = length(Hosts),
    [#{report_name => hosts, key => count, value => NumberOfHosts}].

get_modules() ->
    Hosts = ejabberd_config:get_global_option(hosts),
    ModulesWithOpts = lists:flatten(
        lists:map(fun gen_mod:loaded_modules_with_opts/1, Hosts)),
    lists:map(
        fun({Module, Opts}) ->
            Backend = proplists:get_value(backend, Opts, none),
            #{report_name => Module, key => backend, value => Backend}
        end, ModulesWithOpts).

get_uptime() ->
    {Uptime, _} = statistics(wall_clock),
    UptimeSeconds = Uptime div 1000,
    {D, {H, M, S}} = calendar:seconds_to_daystime(UptimeSeconds),
    Formatted = io_lib:format("~4..0B-~2..0B:~2..0B:~2..0B", [D,H,M,S]),
    [#{report_name => cluster, key => uptime, value => Formatted}].

get_cluster_size() ->
    NodesNo = length(nodes()) + 1,
    [#{report_name => cluster, key => number_of_nodes, value => NodesNo}].

%%get_loglevel() ->
%%    Loglevels = ejabberd_loglevel:get(),
%%    [{_Module, {_N, Loglevel}} | _T ] = Loglevels, % TODO which loglevel should be chosen?
%%    [#{report_name => cluster, key => log_level_configured, value => Loglevel}].
