-module(topo).
-import(lists,[nth/2]).
-export([createLine/1,createFull/1,create3D/1]).
-export([printCons/1,printCons3D/1,flatten/1]).

createLine([N1, N2 | []]) -> N1 ! {link, N2};
createLine([N1, N2 | Rest]) ->
    timer:sleep(1),
    N2 ! {link,N1},
    createLine([N2|Rest]).

createFull(Arr) ->
    [X ! {link,Y} || Y <- Arr , X <- Arr].

create3D(Arr) ->
    L = length(Arr),
    [[createLine(X) || X <- Y] || Y <- Arr],
    [[[nth(N,nth(Row,nth(Layer, Arr))) ! {link, nth(N,nth(Row+1,nth(Layer, Arr)))}
        || N<-lists:seq(1,L)]
        || Row<-lists:seq(1,L-1)] 
        || Layer<-lists:seq(1,L)
    ],
    [[[nth(N,nth(Row,nth(Layer, Arr))) ! {link, nth(N,nth(Row,nth(Layer+1, Arr)))}
        || N<-lists:seq(1,L)]
        || Row<-lists:seq(1,L)] 
        || Layer<-lists:seq(1,L-1)
    ].

printCons([]) -> donePrintCons;
printCons([H|T]) ->
    io:format("~p ~n",[process_info(H,links)]),
    printCons(T).
printCons3D(NodeList) ->
    [[printCons(X) || X <- Y] || Y <- NodeList].

flatten([]) -> [];
flatten([H|T]) -> flatten(H) ++ flatten(T);
flatten(H) -> [H].