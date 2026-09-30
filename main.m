close all
clear all
clc

tic
%% Loading Parameters and OP in struct from datasheet and powerflows
%Static parameters
parameters = loadParameters('parameters.csv');
netlist = loadNetlist('netlist.csv');

OP = PF_results(powerflow(parameters,netlist), parameters, netlist);

% Assignation
operating_points_conv = OP_Converters(OP.Converter(1), parameters.Converters(1));
operating_points_line = OP_Line(OP.Line(1), parameters.Lines(1));
operating_points_grid = OP_Grids(OP.Grid(1), parameters.Grids(1));

%% Call all the necessary elements
conv = Converter_GFL(1, 'PQ', parameters.Converters(1), operating_points_conv);
line = Line(1, parameters.Lines(1), operating_points_line);
grid = Grid(1, parameters.Grids(1), operating_points_grid);


%% Build the state spaces
syms_conv = conv.build();
syms_line = line.build();
syms_grid = grid.build();

%% Evaluate OP and Parameters
ss_conv = conv.evaluate(syms_conv);
ss_line = line.evaluate(syms_line);
ss_grid = grid.evaluate(syms_grid);

%% Connection
ss_conv.InputName = {'Pref','Vdc_ref','Vpoc_ref','Vc_d','Vc_q'};
ss_conv.OutputName = {'Ic_d','Ic_q'};

ss_line.InputName = {'Ic_d','Ic_q', 'Ig_d', 'Ig_q'};
ss_line.OutputName = {'Vc_d','Vc_q', 'Vg_d', 'Vg_q'};

ss_grid.InputName = {'V0_d', 'V0_q', 'Vg_d','Vg_q'};
ss_grid.OutputName = {'Ig_d', 'Ig_q'};

SYS = connect( ...
    ss_conv,...
    ss_line,...
    ss_grid,...
    {'Pref','Vdc_ref','Vpoc_ref','V0_d','V0_q'},...
    {'Ic_d','Ic_q','Ig_d','Ig_q','Vc_d','Vc_q','Vg_d','Vg_q'} ...
);

toc

%% Stability analysys
stability_analysis(SYS)

