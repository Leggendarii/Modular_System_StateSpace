function results = powerflow(P,N)

%% ============================================================
% MATPOWER CASE INITIALIZATION
% ============================================================

AC1.version = '2';
AC1.baseMVA = P.System.P_base/1e6;

%% ============================================================
% DETERMINE ALL NETWORK NODES
% ============================================================

nodes = unique([N.From ; N.To]);
nodes(nodes==0) = [];
nb = max(nodes);

%% ============================================================
% BUS MATRIX
% ============================================================

AC1.bus = zeros(nb,13);

for bus = 1:nb

    AC1.bus(bus,:) = [ ...
        bus ...
        1 ...
        0 ...
        0 ...
        0 ...
        0 ...
        1 ...
        1 ...
        0 ...
        P.System.V_base/1e3 ...
        1 ...
        1.1 ...
        0.9 ];

end

%% ============================================================
% GENERATORS
% ============================================================

gen = [];

%% ============================================================
% BRANCHES
% ============================================================

branch = [];

%% ============================================================
% CREATE BUS AND GENERATOR ELEMENTS
% ============================================================

for k = 1:height(N)

    cat  = string(N.Category(k));
    id   = N.ID(k);
    par  = string(N.Parameter(k));
    from = N.From(k);
    to   = N.To(k);

    if ~(from==0 || to==0)
        continue
    end

    bus = max(from,to);

    %% --------------------------------------------------------
    % PV
    %% --------------------------------------------------------

    if (cat=="Converter" || cat=="Grid") && par=="PV"

        if cat=="Converter"

            Pset = P.Converters(id).P_set;
            Pgen = Pset * P.Converters(id).S_nom / 1e6;

        else

            Pset = P.Grids(id).P_set;
            Pgen = Pset * P.System.P_base / 1e6;

        end

        AC1.bus(bus,2) = 2;

        gen(end+1,:) = [ ...
            bus ...
            Pgen ...
            0 ...
            999 ...
            -999 ...
            1.0 ...
            AC1.baseMVA ...
            1 ...
            999 ...
            -999 ];

    %% --------------------------------------------------------
    % PQ
    %% --------------------------------------------------------

    elseif (cat=="Converter" || cat=="Grid") && par=="PQ"

        if cat=="Converter"

            Pset = P.Converters(id).P_set;
            Qset = P.Converters(id).Q_set;

            Pinj = Pset * P.Converters(id).S_nom / 1e6;
            Qinj = Qset * P.Converters(id).S_nom / 1e6;

        else

            Pset = P.Grids(id).P_set;
            Qset = P.Grids(id).Q_set;

            Pinj = Pset * P.System.P_base / 1e6;
            Qinj = Qset * P.System.P_base / 1e6;

        end

        AC1.bus(bus,3) = -Pinj;
        AC1.bus(bus,4) = -Qinj;

    %% --------------------------------------------------------
    % SLACK
    %% --------------------------------------------------------

    elseif (cat=="Converter" || cat=="Grid") && par=="Slack"

        AC1.bus(bus,2) = 3;

        gen(end+1,:) = [ ...
            bus ...
            0 ...
            0 ...
            999 ...
            -999 ...
            1.0 ...
            AC1.baseMVA ...
            1 ...
            999 ...
            -999 ];

    %% --------------------------------------------------------
    % LINE SHUNT CAPACITANCE
    %% --------------------------------------------------------

    elseif cat=="Line" && par=="C_line"

        B = P.Lines(id).C_line/2;

        AC1.bus(bus,6) = ...
            AC1.bus(bus,6) + B;

    end

end

%% ============================================================
% CONVERTER RL BRANCHES
% ============================================================

for k = 1:height(N)

    if string(N.Category(k)) ~= "Converter"
        continue
    end

    if string(N.Parameter(k)) ~= "R_vsc2"
        continue
    end

    id = N.ID(k);

    R = P.Converters(id).R_vsc2 * P.System.P_base/P.Converters(id).S_nom;
    X = P.Converters(id).L_vsc2 * P.System.P_base/P.Converters(id).S_nom;

    branch(end+1,:) = [ ...
        N.From(k) ...
        N.To(k) ...
        R ...
        X ...
        0 ...
        250 250 250 ...
        0 0 1 ...
        -360 360 ];

end

%% ============================================================
% RL BRANCHES
% ============================================================

for k = 1:height(N)

    if string(N.Category(k)) ~= "RL"
        continue
    end

    if string(N.Parameter(k)) ~= "R"
        continue
    end

    id = N.ID(k);

    R = P.RL(id).R;
    X = P.RL(id).L;

    branch(end+1,:) = [ ...
        N.From(k) ...
        N.To(k) ...
        R ...
        X ...
        0 ...
        250 250 250 ...
        0 0 1 ...
        -360 360 ];

end

%% ============================================================
% LINE RL BRANCHES
% ============================================================

for k = 1:height(N)

    if string(N.Category(k)) ~= "Line"
        continue
    end

    if string(N.Parameter(k)) ~= "R_line"
        continue
    end

    id = N.ID(k);

    R = P.Lines(id).R_line;
    X = P.Lines(id).L_line;

    branch(end+1,:) = [ ...
        N.From(k) ...
        N.To(k) ...
        R ...
        X ...
        0 ...
        250 250 250 ...
        0 0 1 ...
        -360 360 ];

end

%% ============================================================
% GRID THEVENIN BRANCHES
% ============================================================

for k = 1:height(N)

    if string(N.Category(k)) ~= "Grid"
        continue
    end

    if string(N.Parameter(k)) ~= "R_grid"
        continue
    end

    id = N.ID(k);

    R = P.Grids(id).R_grid;
    X = P.Grids(id).L_grid;

    branch(end+1,:) = [ ...
        N.From(k) ...
        N.To(k) ...
        R ...
        X ...
        0 ...
        250 250 250 ...
        0 0 1 ...
        -360 360 ];

end

%% ============================================================
% FINAL MATPOWER MATRICES
% ============================================================

AC1.gen = gen;
AC1.branch = branch;

AC1.gencost = repmat( ...
    [2 0 0 3 0 0 0], ...
    size(gen,1),1);

%% ============================================================
% RUN POWER FLOW
% ============================================================

results = runpf(AC1);

end