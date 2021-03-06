%%%-------------------------------------------------------------------
%%% @author syrett <youyou.li78@gmail.com>
%%% @doc
%%% some good functions for erlang
%%% @end
%%% #Time-stamp: <syrett 2013-07-11 13:47:39>
%%% Created :  20 Jul 2012 by syrett <youyou.li78@gmail.com>
%%%-------------------------------------------------------------------

-module(erlang_utils).
-compile(export_all).

%% @doc
%% 和lists:foldl/3 用法相同,只是在当Acc为{out, Accu}时，将跳出循环
%% @spec foldl_out(F, Acc0, [Hd|Tail]) -> AccOut
%% @end
foldl_out(_F, {out, Accu}, _List) ->
    Accu;
foldl_out(F, Accu, [Hd|Tail]) ->
    foldl_out(F, F(Hd, Accu), Tail);
foldl_out(F, Accu, []) when is_function(F, 2) -> Accu.

%% @doc
%% @spec guid(Len) -> {ok, Value} | exit
%% @spec guid(Len, Fun) ->  {ok, Value} | exit
%% 根据Fun函数规则产生一个长度为Len的随机字符串
%% @end
guid(Len) -> guid(Len, fun(_)-> true end).
guid(Len, Fun)-> guid(Len, Fun, 10).
guid(_Len, _Fun, 0) -> {error, reach_max_guid_try_limit};
guid(Len, Fun, Step) when (Len>0) and (Len=<32) ->
    <<N:128>> = erlang:md5(erlang:term_to_binary({erlang:now(),self(),node(),Step})),
    Value = string:substr(lists:flatten(io_lib:format("~-32.36.0B",[N])), 1, Len),
    case Fun(Value) of
        false -> guid(Len,Fun, Step-1);
        _ -> {ok, Value}
    end.

%% @doc
%% 强制转化数据的类型
%% @end
be_atom(X) when is_atom(X)-> X;
be_atom(X) when is_integer(X)-> be_atom(integer_to_list(X));
be_atom(X) when is_list(X)-> list_to_atom(X);
be_atom(X) when is_binary(X)-> be_atom(binary_to_list(X)).

be_list(X) when is_list(X)-> X;
be_list(X) when is_integer(X) -> integer_to_list(X);
be_list(X) when is_atom(X) -> atom_to_list(X);
be_list(X) when is_binary(X) -> binary_to_list(X);
be_list(X) -> lists:flatten(io_lib:format("~p",[X])).

be_integer(X) when is_list(X) ->
    list_to_integer(X);
be_integer(X) when is_integer(X) ->    X;
be_integer(X) when is_atom(X) ->
    list_to_integer(atom_to_list(X)).

be_bin(X) when is_binary(X)->X;
be_bin(X) when is_atom(X)->list_to_binary(atom_to_list(X));
be_bin(X) when is_integer(X)-> list_to_binary(integer_to_list(X));
be_bin(X)-> list_to_binary(be_list(X)).

%% @doc
%% md5
%% @end
md5(Str)->md5(Str,16).
md5(Str,C) when is_list(Str), C == 16 ->
    md5_hex(Str);
md5(Str,C) when is_list(Str) ->
    md5(iolist_to_binary(Str),C);
md5(BinStr,C) ->
    <<N:128>> = erlang:md5(BinStr),
    [Md5] = io_lib:format( lists:flatten([$~,$.]++io_lib:format("~pb",[C])), [N]),
    Md5.

md5_hex(Str) ->
    Md5_list = binary_to_list(erlang:md5(Str)),
    lists:flatten(list_to_hex(Md5_list)).
list_to_hex(List) ->
    lists:map(fun(X) -> int_to_hex(X) end, List).
int_to_hex(N) when N < 256 ->
    [hex(N div 16), hex(N rem 16)].
hex(N) when N < 10 ->
    $0+N;
hex(N) when N >= 10, N < 16 ->
    $a + (N - 10).


delete_slide_item([{{[$/|KTail],Rev}, Val}|T]) ->
    delete_slide_item_t([{{KTail,Rev}, Val}|T], []);
delete_slide_item([H|T]) ->
    delete_slide_item_t(T, [H]).

delete_slide_item_t([], List) ->
    List;
delete_slide_item_t([{{[$/|KTail],Rev}, Val}|T], List) ->
    delete_slide_item_t([{{KTail,Rev}, Val}|T], List);
delete_slide_item_t([H|T], List) ->
    delete_slide_item_t(T, [H|List]).


file_diff() ->
    LittleFile = "/home/liyouyou/Dropbox/Codes/data/res",
    BigFile = "/home/liyouyou/Dropbox/Codes/data/loop",
    {ok, File1} = file:read_file(LittleFile),
    Filter = re:split(File1, ","),
    L1 = lists:foldl(fun(X, {4, Acc0}) ->
		       {1, [binary_to_list(X) || Acc0]};
		  (_, {N, Acc0}) ->
		       {N+1, Acc0}
	       end, {1, []}, Filter),
    erlang:display(L1).
    
exit() ->
    catch apply(erlang_utils, a, []).
%    erlang:display(A).



%% @doc
%% @spec get_tuplelist(String) -> TupleList()
%% 把有规则的string字符串解析为[{key, value}....]的格式
%% example: [{k1, v1},{k2,v2}] = get_tuplelist("k1=v1;k2=v2")
%% @end
get_tuplelist(String) ->
    get_tuplelist(String, "", []).

get_tuplelist([], _, TL) ->
    TL;
get_tuplelist([$= | T], Key, TL) ->
    {Value, T1} = get_value(T),
    get_tuplelist(T1, "", [{Key, Value}|TL]);
get_tuplelist([H|T], Key, TL) ->
    get_tuplelist(T, Key ++ [H], TL).

get_value(String) ->
    get_value(String, "").

get_value([], Value) ->
    {Value, []};
get_value([$;|T], Value) ->
    {Value, T};
get_value([H|T], Value) ->
    get_value(T, Value ++ [H]).

fun_time(Module, Func, Args) ->
    T1 = now(),
    apply(Module, Func, Args),
    T2 = now(),
    Diff = timer:now_diff(T2,T1),
    io:format("diff time:~p\n", [Diff]).
    
    
%%to_datetime(<<"Fri, 10 May 2013 09:50:03 GMT">>) ->
to_datetime(Bin) when is_binary(Bin) ->
    to_datetime(binary_to_list(Bin));
to_datetime(Str) ->
    Day = list_to_integer(string:substr(Str, 6,2)),
    Month1 = string:substr(Str, 9, 3),
    Month = to_month(Month1),
    Year = list_to_integer(string:substr(Str, 13, 4)),
    Time1 = string:substr(Str, 18, 8),
    Time = [list_to_integer(X) || X <- string:tokens(Time1, ":")],
    {{Year, Month, Day}, list_to_tuple(Time)}.

to_month("Jan") -> 1;
to_month("Feb") -> 2;
to_month("Mar") -> 3;
to_month("Apr") -> 4;
to_month("May") -> 5;
to_month("Jun") -> 6;
to_month("Jul") -> 7;
to_month("Aug") -> 8;
to_month("Sep") -> 9;
to_month("Oct") -> 10;
to_month("Nov") -> 11;
to_month("Dec") -> 12.

%% 小写换成大写, '-' 换成 '_'
param_char(Int_char) when Int_char < 123 and Int_char > 60 -> 
    Int_char - 32;
param_char($-) -> $_;
param_char(Ch) -> Ch.

%% 高亮显示字体
highlight(String)->
    lists:flatten(io_lib:format("\033[0;1m~s\033[0m",[String])).
