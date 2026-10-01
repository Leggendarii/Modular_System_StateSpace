function P = loadParameters(csv_file_name)

parameter = readtable(csv_file_name,'TextType','string');

getNum = @(cat,id,par) ...
    parameter.Value( ...
        strcmp(parameter.Category,cat) & ...
        parameter.ID == id & ...
        strcmp(parameter.Parameter,par));

getStr = @(cat,id,par) ...
    char(parameter.Value( ...
    parameter.Category==cat & ...
    parameter.ID==id & ...
    parameter.Parameter==par));



%% System

P.System.Ts     = getNum("System",0,"Ts")*1e-6;
P.System.f_base = getNum("System",0,"f_base");
P.System.V_base = getNum("System",0,"V_base")*1e3;
P.System.P_base = getNum("System",0,"P_base")*1e6;

%% Base quantities

P.System.omega_b = 2*pi*P.System.f_base;

P.System.Z_base = ...
    P.System.V_base^2/P.System.P_base;

P.System.L_base = ...
    P.System.Z_base/P.System.omega_b;

P.System.C_base = ...
    1/(P.System.Z_base*P.System.omega_b);

%% Converters

conv_ids = unique(parameter.ID(parameter.Category=="Converter"));

for k = 1:length(conv_ids)

    id = conv_ids(k);

    P.Converters(id).S_nom = ...
    getNum("Converter",id,"S_nom")*1e6;

    P.Converters(id).f_base = P.System.f_base;
    P.Converters(id).V_base = P.System.V_base;
    P.Converters(id).P_base = P.System.P_base;
    
    P.Converters(id).omega_b = P.System.omega_b;
    P.Converters(id).Z_base = P.Converters(id).V_base^2 / P.Converters(id).S_nom;
    P.Converters(id).L_base = P.Converters(id).Z_base / P.Converters(id).omega_b;
    P.Converters(id).C_base = 1 / (P.Converters(id).Z_base * P.Converters(id).omega_b);

    P.Converters(id).P_set = ...
        getNum("Converter",id,"P_set");

    P.Converters(id).Q_set = ...
        getNum("Converter",id,"Q_set");

    P.Converters(id).L_vsc = ...
    getNum("Converter",id,"L_vsc") / P.Converters(id).L_base;

    P.Converters(id).C_vsc = ...
        getNum("Converter",id,"C_vsc") / P.Converters(id).C_base;
    
    P.Converters(id).R_vsc = ...
        getNum("Converter",id,"R_vsc") / P.Converters(id).Z_base;
    
    P.Converters(id).R_vsc2 = ...
        getNum("Converter",id,"R_vsc2") / P.Converters(id).Z_base;
    
    P.Converters(id).L_vsc2 = ...
        getNum("Converter",id,"L_vsc2") / P.Converters(id).L_base;

    P.Converters(id).Kp_outer_V = ...
        getNum("Converter",id,"Kp_outer_V");

    P.Converters(id).Ki_outer_V = ...
        getNum("Converter",id,"Ki_outer_V");

    P.Converters(id).Kp_outer_P = ...
        getNum("Converter",id,"Kp_outer_P");

    P.Converters(id).Ki_outer_P = ...
        getNum("Converter",id,"Ki_outer_P");

    P.Converters(id).Kp_inner_d = ...
        getNum("Converter",id,"Kp_inner_d");

    P.Converters(id).Ki_inner_d = ...
        getNum("Converter",id,"Ki_inner_d");

    P.Converters(id).Kp_inner_q = ...
        getNum("Converter",id,"Kp_inner_q");

    P.Converters(id).Ki_inner_q = ...
        getNum("Converter",id,"Ki_inner_q");

    P.Converters(id).Kp_pll = ...
        getNum("Converter",id,"Kp_pll");

    P.Converters(id).Ki_pll = ...
        getNum("Converter",id,"Ki_pll");

    P.Converters(id).T1 = ...
        getNum("Converter",id,"T1");

    P.Converters(id).T2 = ...
        getNum("Converter",id,"T2");

    [P.Converters(id).C_dc, P.Converters(id).V_dc] = DC_Cap(P.System.V_base, P.Converters(id).S_nom);

    P.Converters(id).t_charge = 0.5;

    P.Converters(id).I_charge = ...
        P.Converters(id).C_dc * ...
        P.Converters(id).V_dc / ...
        P.Converters(id).t_charge;

end

%% Grids

grid_ids = unique(parameter.ID(parameter.Category=="Grid"));

for k = 1:length(grid_ids)

    id = grid_ids(k);

    P.Grids(id).f_base = P.System.f_base;
    P.Grids(id).V_base = P.System.V_base;
    P.Grids(id).P_base = P.System.P_base;
    
    P.Grids(id).omega_b = P.System.omega_b;
    P.Grids(id).Z_base  = P.System.Z_base;
    P.Grids(id).L_base  = P.System.L_base;
    P.Grids(id).C_base  = P.System.C_base;

    P.Grids(id).SCR = ...
        getNum("Grid",id,"SCR");

    P.Grids(id).XR = ...
        getNum("Grid",id,"XR");

    P.Grids(id).P_set = ...
    getNum("Grid",id,"P_set");

    P.Grids(id).Q_set = ...
    getNum("Grid",id,"Q_set");

    [P.Grids(id).L_grid,...
     P.Grids(id).R_grid] = ...
        thevenin( ...
        P.Grids(id).SCR,...
        P.Grids(id).XR,...
        P.System.V_base,...
        P.System.P_base,...
        P.System.f_base);

    P.Grids(id).R_grid = P.Grids(id).R_grid / P.Grids(id).Z_base;
    P.Grids(id).L_grid = P.Grids(id).L_grid / P.Grids(id).L_base;

end

%% Lines

line_ids = unique(parameter.ID(parameter.Category=="Line"));

for k = 1:length(line_ids)

    id = line_ids(k);

    P.Lines(id).S_nom = getNum("Line",id,"S_nom")*1e6;
    
    P.Lines(id).f_base = P.System.f_base;
    P.Lines(id).V_base = P.System.V_base;
    P.Lines(id).omega_b = P.System.omega_b;
    
    P.Lines(id).R_line = getNum("Line",id,"R_line") / P.System.Z_base;
    P.Lines(id).L_line = getNum("Line",id,"L_line") / P.System.L_base;
    P.Lines(id).C_line = getNum("Line",id,"C_line") / P.System.C_base;

end

%% RL branches
rl_ids = unique(parameter.ID(parameter.Category=="RL"));

for k = 1:length(rl_ids)

    id = rl_ids(k);

    P.RL(id).S_nom = getNum("RL",id,"S_nom")*1e6;
    
    P.RL(id).f_base = P.System.f_base;
    P.RL(id).V_base = P.System.V_base;
    P.RL(id).omega_b = P.System.omega_b;
    
    P.RL(id).R = getNum("RL",id,"R") / P.System.Z_base;
    P.RL(id).L = getNum("RL",id,"L") / P.System.L_base;
end

end