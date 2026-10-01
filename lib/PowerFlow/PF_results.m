function OP = PF_results(results,P,N)

bus    = results.bus;
gen    = results.gen;
branch = results.branch;

%% =====================================================================
% CONVERTERS
%% =====================================================================

conv_idx = 0;

for k = 1:height(N)

    if ~strcmp(N.Category{k},'Converter')
        continue
    end

    if ~(strcmp(N.Parameter{k},'PV') || ...
         strcmp(N.Parameter{k},'PQ'))
        continue
    end

    conv_idx = conv_idx + 1;

    bus_id = max(N.From(k),N.To(k));

    OP.Converter(conv_idx).V_kV = ...
        bus(bus_id,8) * bus(bus_id,10);

    OP.Converter(conv_idx).theta_rad = ...
        deg2rad(bus(bus_id,9));

    id = N.ID(k);

    if strcmp(N.Parameter{k},'PV')

        gidx = find(gen(:,1)==bus_id,1);

        OP.Converter(conv_idx).P_MW = gen(gidx,2);
        OP.Converter(conv_idx).Q_MVAr = gen(gidx,3);

    else

        OP.Converter(conv_idx).P_MW = ...
            P.Converters(id).P_set * ...
            P.System.P_base/1e6;

        OP.Converter(conv_idx).Q_MVAr = ...
            P.Converters(id).Q_set * ...
            P.System.P_base/1e6;

    end

end

%% =====================================================================
% GRIDS
%% =====================================================================
grid_idx = 0;

for k = 1:height(N)

    if ~strcmp(N.Category{k},'Grid')
        continue
    end

    if ~(strcmp(N.Parameter{k},'Slack') || ...
         strcmp(N.Parameter{k},'PV')    || ...
         strcmp(N.Parameter{k},'PQ'))
        continue
    end

    grid_idx = grid_idx + 1;

    bus_id = max(N.From(k),N.To(k));

    OP.Grid(grid_idx).Type = N.Parameter{k};

    OP.Grid(grid_idx).V_kV = ...
        bus(bus_id,8)*bus(bus_id,10);

    OP.Grid(grid_idx).theta_rad = ...
        deg2rad(bus(bus_id,9));

    if strcmp(N.Parameter{k},'Slack')

        gidx = find(gen(:,1)==bus_id,1);

        OP.Grid(grid_idx).P_MW = gen(gidx,2);
        OP.Grid(grid_idx).Q_MVAr = gen(gidx,3);

    elseif strcmp(N.Parameter{k},'PV')

        gidx = find(gen(:,1)==bus_id,1);

        OP.Grid(grid_idx).P_MW = gen(gidx,2);
        OP.Grid(grid_idx).Q_MVAr = gen(gidx,3);

    elseif strcmp(N.Parameter{k},'PQ')

        id = N.ID(k);

        OP.Grid(grid_idx).P_MW = ...
            P.Grids(id).P_set * ...
            P.System.P_base/1e6;

        OP.Grid(grid_idx).Q_MVAr = ...
            P.Grids(id).Q_set * ...
            P.System.P_base/1e6;

    end

end

%% =====================================================================
% LINES
%% =====================================================================

line_idx = 0;

for k = 1:height(N)

    if ~strcmp(N.Category{k},'Line')
        continue
    end

    if ~strcmp(N.Parameter{k},'R_line')
        continue
    end

    line_idx = line_idx + 1;

    from_bus = N.From(k);
    to_bus   = N.To(k);

    V1_mag_kV = ...
        bus(from_bus,8)*bus(from_bus,10);

    V2_mag_kV = ...
        bus(to_bus,8)*bus(to_bus,10);

    th1 = deg2rad(bus(from_bus,9));
    th2 = deg2rad(bus(to_bus,9));

    OP.Line(line_idx).V1_kV = V1_mag_kV;
    OP.Line(line_idx).theta1_rad = th1;

    OP.Line(line_idx).V2_kV = V2_mag_kV;
    OP.Line(line_idx).theta2_rad = th2;

    br = find( ...
        branch(:,1)==from_bus & ...
        branch(:,2)==to_bus ,1);

    P12 = branch(br,14);
    Q12 = branch(br,15);

    S12 = (P12 + 1j*Q12)*1e6;

    V1 = V1_mag_kV*1e3*exp(1j*th1);

    I12 = conj(S12/V1);

    OP.Line(line_idx).I_kA = abs(I12)/1e3;
    OP.Line(line_idx).I_angle_rad = angle(I12);

end

%% =====================================================================
% RL BRANCHES
%% =====================================================================
rl_idx = 0;

for k = 1:height(N)

    if string(N.Category(k)) ~= "RL"
        continue
    end

    if string(N.Parameter(k)) ~= "R"
        continue
    end

    rl_idx = rl_idx + 1;

    from_bus = N.From(k);
    to_bus   = N.To(k);

    V1_mag_kV = bus(from_bus,8) * bus(from_bus,10);
    V2_mag_kV = bus(to_bus,8)   * bus(to_bus,10);

    th1 = deg2rad(bus(from_bus,9));
    th2 = deg2rad(bus(to_bus,9));

    OP.RL(rl_idx).V1_kV      = V1_mag_kV;
    OP.RL(rl_idx).theta1_rad = th1;

    OP.RL(rl_idx).V2_kV      = V2_mag_kV;
    OP.RL(rl_idx).theta2_rad = th2;

end


end
