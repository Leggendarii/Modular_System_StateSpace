%% CASE STUDY 1: OWPP + Onshore STATCOM

% Converter(1) : Aggregated OWPP converter (PV operation)
% Line(1)      : Equivalent transmission line
% Grid(1)      : External AC grid equivalent
% Converter(2) : STATCOM connected at the onshore PCC
%
% Topology:
%
% OWPP Converter ---- Line ---- PCC ---- Grid
%                               |
%                            STATCOM
%

%% Clear all
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
operating_points_conv_1 = OP_Converters(OP.Converter(1), parameters.Converters(1));
operating_points_conv_2 = OP_Converters(OP.Converter(2), parameters.Converters(2));
operating_points_line = OP_Line(OP.Line(1), parameters.Lines(1));
operating_points_grid = OP_Grids(OP.Grid(1), parameters.Grids(1));


%% Call all the necessary elements
conv_1 = Converter_GFL(1, 'PV', parameters.Converters(1), operating_points_conv_1);
conv_2 = Converter_GFL(2, 'PV', parameters.Converters(2), operating_points_conv_2);
line = Line(1, parameters.Lines(1), operating_points_line);
grid = Grid(1, parameters.Grids(1), operating_points_grid);



%% Build the state spaces
syms_conv_1 = conv_1.build();
syms_conv_2 = conv_2.build();
syms_line = line.build();
syms_grid = grid.build();


%% Evaluate OP and Parameters
ss_conv_1 = conv_1.evaluate(syms_conv_1);
ss_conv_2 = conv_2.evaluate(syms_conv_2);
ss_line = line.evaluate(syms_line);
ss_grid = grid.evaluate(syms_grid);


%% Connection
% Converter
ss_conv_1.InputName  = {'Pref','Vdc_ref','Vpoc_ref1','Vc_d','Vc_q'};
ss_conv_1.OutputName = {'Ic1_d','Ic1_q'};

% Line
ss_line.InputName  = {'Ic1_d','Ic1_q','Ig_d','Ig_q'};
ss_line.OutputName = {'Vc_d','Vc_q','Vg_d','Vg_q'};

% Grid
ss_grid.InputName  = {'V0_1_d','V0_1_q','Vg_d','Vg_q'};
ss_grid.OutputName = {'Ig1_d','Ig1_q'};

% Converter 2
ss_conv_2.InputName = {'Pref2','Vdc_ref2','Vpoc_ref2','Vg_d','Vg_q'};
ss_conv_2.OutputName = {'Ic2_d','Ic2_q'};


% KCL node 3
S = sumblk('Ig_d =  Ig1_d - Ic2_d');  
S2 = sumblk('Ig_q =  Ig1_q - Ic2_q');

% Connect
SYS = connect( ...
    ss_conv_1,...
    ss_line,...
    ss_grid,...
    ss_conv_2,...
    S,...
    S2,...
    {'Pref','Vdc_ref','Vpoc_ref1',...
     'Pref2','Vdc_ref2','Vpoc_ref2',...
     'V0_1_d','V0_1_q'},...
    {'Ic1_d','Ic1_q',...
     'Ic2_d','Ic2_q',...
     'Ig_d','Ig_q',...
     'Vc_d','Vc_q',...
     'Vg_d','Vg_q'});

toc

%% Stability analysys
stability_analysis(SYS)

