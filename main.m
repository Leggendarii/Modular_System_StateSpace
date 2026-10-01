close all
clear all


tic
%% Loading Parameters and OP in struct from datasheet and powerflows
%Static parameters
parameters = loadParameters('parameters.csv');
netlist = loadNetlist('netlist.csv');

OP = PF_results(powerflow(parameters,netlist), parameters, netlist);

% Assignation
operating_points_conv_1 = OP_Converters(OP.Converter(1), parameters.Converters(1));
operating_points_conv_2 = OP_Converters(OP.Converter(2), parameters.Converters(2));
operating_points_line_1 = OP_Line(OP.Line(1), parameters.Lines(1));
operating_points_line_2 = OP_Line(OP.Line(2), parameters.Lines(2));
operating_points_grid = OP_Grids(OP.Grid(1), parameters.Grids(1));
operating_points_rl = OP_RL(OP.RL(1), parameters.RL(1));


%% Call all the necessary elements
conv_1 = Converter_GFL(1, 'PV', parameters.Converters(1), operating_points_conv_1);
conv_2 = Converter_GFL(2, 'PV', parameters.Converters(2), operating_points_conv_2);
line_1 = Line(1, parameters.Lines(1), operating_points_line_1);
line_2 = Line(2, parameters.Lines(2), operating_points_line_2);
grid = Grid(1, parameters.Grids(1), operating_points_grid);
rl = RL(1,parameters.RL(1),operating_points_rl);



%% Build the state spaces
syms_conv_1 = conv_1.build();
syms_conv_2 = conv_2.build();
syms_line_1 = line_1.build();
syms_line_2 = line_2.build();
syms_grid = grid.build();
syms_rl = rl.build();


%% Evaluate OP and Parameters
ss_conv_1 = conv_1.evaluate(syms_conv_1);
ss_conv_2 = conv_2.evaluate(syms_conv_2);
ss_line_1 = line_1.evaluate(syms_line_1);
ss_line_2 = line_2.evaluate(syms_line_2);
ss_grid = grid.evaluate(syms_grid);
ss_rl = rl.evaluate(syms_rl);


%% Connection

% Converter 1
ss_conv_1.InputName  = {'Pref1','Vdc_ref1','Vpoc_ref1','V1_d','V1_q'};
ss_conv_1.OutputName = {'Ic1_d','Ic1_q'};

% Line 1 (Node2 <-> Node3)
ss_line_1.InputName  = {'Ic1_d','Ic1_q','Irl_d','Irl_q'};
ss_line_1.OutputName = {'V1_d','V1_q','V3_d','V3_q'};

% RL (Node3 <-> Node4)
ss_rl.InputName  = {'V3_d','V3_q','V4_d','V4_q'};
ss_rl.OutputName = {'Irl_d','Irl_q'};

% Line 2 (Node4 <-> Node5)
ss_line_2.InputName  = {'Irl_d','Irl_q','Ig_d','Ig_q'};
ss_line_2.OutputName = {'V4_d','V4_q','V5_d','V5_q'};

% Grid
ss_grid.InputName  = {'V0_1_d','V0_1_q','V5_d','V5_q'};
ss_grid.OutputName = {'Ig1_d','Ig1_q'};

% Converter 2
ss_conv_2.InputName  = {'Pref2','Vdc_ref2','Vpoc_ref2','V5_d','V5_q'};
ss_conv_2.OutputName = {'Ic2_d','Ic2_q'};

% PCC KCL
S1 = sumblk('Ig_d = Ig1_d - Ic2_d');
S2 = sumblk('Ig_q = Ig1_q - Ic2_q');

% Connect
SYS = connect( ...
    ss_conv_1,...
    ss_line_1,...
    ss_rl,...
    ss_line_2,...
    ss_grid,...
    ss_conv_2,...
    S1,...
    S2,...
    {'Pref1','Vdc_ref1','Vpoc_ref1',...
     'Pref2','Vdc_ref2','Vpoc_ref2',...
     'V0_1_d','V0_1_q'},...
    {'Ic1_d','Ic1_q',...
     'Ic2_d','Ic2_q',...
     'Irl_d','Irl_q',...
     'Ig_d','Ig_q',...
     'V3_d','V3_q',...
     'V4_d','V4_q',...
     'V5_d','V5_q'});


toc

%% Stability analysys
stability_analysis(SYS)

