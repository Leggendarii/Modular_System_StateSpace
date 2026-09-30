classdef Converter_GFL

    properties
        ID
        Mode
        Parameters
        OperatingPoints
        StateNames
    end

    methods
        function obj = Converter_GFL(ID, mode, parameters, operating_points)
            obj.ID = ID;
            obj.Mode = upper(mode);
            obj.Parameters = parameters;
            obj.OperatingPoints = operating_points;
            obj.StateNames = obj.generateStateNames();
        end

        function symb = build(obj)

            %% Definizione simbolica variabili di stato e ingressi

            syms IL_d_s IL_q_s Iout_d_s Iout_q_s Vpoc_d_s Vpoc_q_s Flux_PoC W_Q Qd Qq Flux_PLL Theta Vdc_mes Flux_laglead Flux_DC ...
                 Iref_d_c Iref_q_c Vvsc_d_c Vvsc_q_c Vpoc_d_c Vpoc_q_c IL_d_c IL_q_c Vvsc_d_s Vvsc_q_s Vdc_filt Iout_d_c Iout_q_c...
                 R1 L1 R2 L2 C3 Wn Kp_out_P Ki_out_P Kp_out_V Ki_out_V Kp_in_d Ki_in_d Kp_in_q Ki_in_q Kp_PLL Ki_PLL ...
                 P_ref Vpoc_ref Vdc_ref Q_ref Cdc Vdc_n Pn sT1 sT2 Vin_d_s Vin_q_s
            
            %% Vettore stato, algebraico e ingresso
            if strcmp(obj.Mode,'PV')
            x = [IL_d_s; IL_q_s; Vpoc_d_s; Vpoc_q_s; Flux_DC; Flux_PoC; Qd; Qq; Flux_PLL; Theta; Vdc_mes; Flux_laglead; Iout_d_s; Iout_q_s];
            u = [P_ref; Vdc_ref; Vpoc_ref; Vin_d_s; Vin_q_s];
            elseif strcmp(obj.Mode,'PQ')
            x = [IL_d_s; IL_q_s; Vpoc_d_s; Vpoc_q_s; Flux_DC; W_Q; Qd; Qq; Flux_PLL; Theta; Vdc_mes; Flux_laglead; Iout_d_s; Iout_q_s];
            u = [P_ref; Vdc_ref; Q_ref; Vin_d_s; Vin_q_s];
            else
                error('Converter mode must be PQ or PV')
            end
            h = [Iout_d_s; Iout_q_s];
            params = [R1; L1; R2; L2; C3; Wn; Kp_out_P; Kp_out_V; Ki_out_V; Ki_out_P; Kp_in_d; Ki_in_d; Kp_in_q; Ki_in_q; Kp_PLL; Ki_PLL; Cdc; Vdc_n; Pn; sT1; sT2];  
            y = [Iref_d_c; Iref_q_c; Vvsc_d_c; Vvsc_q_c; Vpoc_d_c; Vpoc_q_c; IL_d_c; IL_q_c; Vvsc_d_s; Vvsc_q_s; Vdc_filt; Iout_d_c; Iout_q_c];
           
            
            %% Equazioni differenziali 
            f1 = (Wn/L1)*(-R1*IL_d_s + L1*IL_q_s + Vvsc_d_s - Vpoc_d_s);                            % iL_d_s
            f2 = (Wn/L1)*(-L1*IL_d_s - R1*IL_q_s + Vvsc_q_s - Vpoc_q_s);                            % iL_q_s                        
            f3 = (IL_d_s - Iout_d_s + C3*Vpoc_q_s)*Wn/C3;                                           % vpoc_d_s
            f4 = (IL_q_s - Iout_q_s - C3*Vpoc_d_s)*Wn/C3;                                           % vpoc_q_s
            f5 = (Vdc_filt - Vdc_ref);                                                              % flux_dc
            if strcmp(obj.Mode,'PV')
            f6 = sqrt(Vpoc_q_c^2 + Vpoc_d_c^2) - Vpoc_ref;                                          % flux_poc
            elseif strcmp(obj.Mode,'PQ')
            f6 = -Q_ref + (Vpoc_q_c*Iout_d_c - Vpoc_d_c*Iout_q_c);                                  % W_Q
            end
            f7 = Iref_d_c - IL_d_c;                                                                 % Qd
            f8 = Iref_q_c - IL_q_c;                                                                 % Qq
            f9 = Vpoc_q_c;                                                                          % flux_PLL
            f10 = Kp_PLL * Vpoc_q_c + Ki_PLL * Flux_PLL;                                            % theta
            f11 = (P_ref - (Vpoc_d_c*Iout_d_c + Vpoc_q_c*Iout_q_c))/(Cdc * Vdc_mes) *(Pn/Vdc_n^2);  % vdc_mes
            f12 = -(1/sT2)*Flux_laglead + Vdc_mes;                                                  % flux_laglead
            f13 = (Wn/L2)*(-R2*Iout_d_s + L2*Iout_q_s + Vpoc_d_s - Vin_d_s);                        % iout_d_s
            f14 = (Wn/L2)*(-L2*Iout_d_s - R2*Iout_q_s + Vpoc_q_s - Vin_q_s);                        % iout_q_s   
            
            f = [f1; f2; f3; f4; f5; f6; f7; f8; f9; f10; f11; f12; f13; f14];
            %% Frame conversion matrix
            T = [cos(Theta) sin(Theta); -sin(Theta) cos(Theta)];
            
            % Transform grid voltages to converter frame
            v_poc_dq_c = T * [Vpoc_d_s; Vpoc_q_s];
            
            % Transform grid currents to converter frame
            i_out_dq_c = T * [Iout_d_s; Iout_q_s];
            
            % Transform filter currents to converter frame
            i_L_dq_c = T * [IL_d_s; IL_q_s];
            
            % Transform VSC voltages from converter to sync frame
            v_inv_dq_s = inv(T) * [Vvsc_d_c; Vvsc_q_c];
            
            %% Equazioni algebraiche 
            g1 = Kp_out_P * (Vdc_filt - Vdc_ref) + Ki_out_P * Flux_DC - Iref_d_c;                           % iref_d_c
            if strcmp(obj.Mode,'PV')
            g2 = Kp_out_V * (sqrt(Vpoc_q_c^2 + Vpoc_d_c^2) - Vpoc_ref) + Ki_out_V * Flux_PoC - Iref_q_c;    % iref_q_c
            elseif strcmp(obj.Mode,'PQ')
            g2 = Kp_out_V*(-Q_ref + (Vpoc_q_c*Iout_d_c - Vpoc_d_c*Iout_q_c)) + Ki_out_V*W_Q - Iref_q_c;     % iref_q_c
            end
            g3 = (Kp_in_d*(Iref_d_c-IL_d_c) + Ki_in_d*Qd) - Vvsc_d_c;                                       % vvsc_d_c
            g4 = (Kp_in_q*(Iref_q_c-IL_q_c) + Ki_in_q*Qq) - Vvsc_q_c;                                       % vvsc_q_c
            g5 = v_poc_dq_c(1) - Vpoc_d_c;                                                                  % vpoc_d_c
            g6 = v_poc_dq_c(2) - Vpoc_q_c;                                                                  % vpoc_q_c
            g7 = i_L_dq_c(1) - IL_d_c;                                                                      % iL_d_c
            g8 = i_L_dq_c(2) - IL_q_c;                                                                      % iL_q_c
            g9 = v_inv_dq_s(1) - Vvsc_d_s;                                                                  % vvsc_d_s
            g10 = v_inv_dq_s(2) - Vvsc_q_s;                                                                 % vvsc_q_s
            g11 = (1/sT2 - sT1/sT2^2)*Flux_laglead + sT1/sT2 * Vdc_mes - Vdc_filt;                          % vdc_filt
            g12 = i_out_dq_c(1) - Iout_d_c;                                                                 % iout_d_c
            g13 = i_out_dq_c(2) - Iout_q_c;                                                                 % iout_q_c
            
            g = [g1, g2, g3, g4, g5, g6, g7, g8, g9, g10, g11, g12, g13];
            
            
            %% Calcolo matrice Jacobiana rispetto allo stato (A) e ingresso (B)

            Fx = jacobian(f,x);
            Fy = jacobian(f,y);
            Fu = jacobian(f,u);

            Gx = jacobian(g,x);
            Gy = jacobian(g,y);
            Gu = jacobian(g,u);

            A = Fx - Fy*(Gy\Gx);
            B = Fu - Fy*(Gy\Gu);

            Hx = jacobian(h,x);
            Hy = jacobian(h,y);
            Hu = jacobian(h,u);
            
            C = Hx - Hy*(Gy\Gx);
            
            D = Hu - Hy*(Gy\Gu);

            %% Impacchettamento modello simbolico
            symb.Mode = obj.Mode;
            symb.x = x; symb.y = y; symb.u = u; symb.h = h; symb.params = params;
            symb.f = f; symb.g = g;
            symb.A = A; symb.B = B; symb.C = C; symb.D = D;
            fprintf('Converter %d State-Space is built.\n', obj.ID);
        end

        function [sys, residuals] = evaluate(obj, symb)

            P = obj.Parameters;
            OP = obj.OperatingPoints;

            x = symb.x; y = symb.y; u = symb.u; params = symb.params;
            f = symb.f; g = symb.g;
            A = symb.A; B = symb.B; C = symb.C; D = symb.D;

            %% Assegnazione condizioni iniziali
            params_eq = [P.R_vsc/P.Z_base; P.L_vsc/P.L_base; P.R_vsc2/P.Z_base; P.L_vsc2/P.L_base; P.C_vsc/P.C_base; P.omega_b; P.Kp_outer_P; P.Kp_outer_V; P.Ki_outer_V; P.Ki_outer_P; P.Kp_inner_d; P.Ki_inner_d; P.Kp_inner_q; P.Ki_inner_q; P.Kp_pll; P.Ki_pll; P.C_dc; P.V_dc; P.P_base; P.T1; P.T2];
            if strcmp(obj.Mode,'PV')
            x_eq = [OP.iL_d_s; OP.iL_q_s; OP.vpoc_d_s; OP.vpoc_q_s; OP.flux_DC/P.Ki_outer_P; OP.flux_PoC/P.Ki_outer_V; OP.qd/P.Ki_inner_d; OP.qq/P.Ki_inner_q; OP.flux_PLL/P.Ki_pll; OP.theta; OP.vdc_mes; OP.vdc_mes*P.T2; OP.iout_d_s; OP.iout_q_s];
            u_eq = [OP.pref; OP.vdc_ref; OP.vpoc_ref; OP.vin_d_s; OP.vin_q_s];
            elseif strcmp(obj.Mode,'PQ')
            x_eq = [OP.iL_d_s; OP.iL_q_s; OP.vpoc_d_s; OP.vpoc_q_s; OP.flux_DC/P.Ki_outer_P; OP.w_q/P.Ki_outer_V; OP.qd/P.Ki_inner_d; OP.qq/P.Ki_inner_q; OP.flux_PLL/P.Ki_pll; OP.theta; OP.vdc_mes; OP.vdc_mes*P.T2; OP.iout_d_s; OP.iout_q_s];
            u_eq = [OP.pref; OP.vdc_ref; OP.qref; OP.vin_d_s; OP.vin_q_s];
            end
            y_eq = [OP.iref_d_c; OP.iref_q_c; OP.vvsc_d_c; OP.vvsc_q_c; OP.vpoc_d_c; OP.vpoc_q_c; OP.iL_d_c; OP.iL_q_c; OP.vvsc_d_s; OP.vvsc_q_s; OP.vdc_mes; OP.iout_d_c; OP.iout_q_c];
            

            %% Equilibrium residuals
            f_eq = double(subs(f, [x; y; u; params], [x_eq; y_eq; u_eq; params_eq]));
            g_eq = double(subs(g, [x; y; u; params], [x_eq; y_eq; u_eq; params_eq]));

            residuals.differential = f_eq;
            residuals.differentialNorm2 = norm(f_eq, 2);
            residuals.differentialNormInf = norm(f_eq, inf);
            residuals.algebraic = g_eq;
            residuals.algebraicNorm2 = norm(g_eq, 2);
            residuals.algebraicNormInf = norm(g_eq, inf);

            fprintf(['\nConverter evaluated, %d equilibrium residuals: ', ...
                '||f||_2=%.3e, ||f||_inf=%.3e, ', ...
                '||g||_2=%.3e, ||g||_inf=%.3e\n'], ...
                obj.ID, residuals.differentialNorm2, ...
                residuals.differentialNormInf, residuals.algebraicNorm2, ...
                residuals.algebraicNormInf);

            %% Creazione elementi state space e assemblaggio
            
            A_lin = double(subs(A, [x; y; u; params], [x_eq; y_eq; u_eq; params_eq]));
            
            B_lin = double(subs(B, [x; y; u; params], [x_eq; y_eq; u_eq; params_eq]));
            
            C_lin = double(subs(C, [x; y; u; params], [x_eq; y_eq; u_eq; params_eq]));
            
            D_lin = double(subs(D, [x; y; u; params], [x_eq; y_eq; u_eq; params_eq]));
            
            
            sys = ss(A_lin, B_lin, C_lin, D_lin);
            
            sys.StateName = cellstr(obj.StateNames);
        end
        
    end
  
    methods (Access = private)

    function names = generateStateNames(obj)
        
        if strcmp(obj.Mode,'PV')
            outer_q_state = 'Flux_Vc';
        elseif strcmp(obj.Mode,'PQ')
            outer_q_state = 'W_Q';
        end
        
        baseNames = { ...
            'VSC.IL_d',...
            'VSC.IL_q',...
            'VSC.Vc_d',...
            'VSC.Vc_q',...
            'VSC.Flux_Vdc',...
            ['VSC.' outer_q_state],...
            'VSC.Q_d',...
            'VSC.Q_q',...
            'VSC.Flux_PLL',...
            'VSC.Theta',...
            'VSC.Vdc',...
            'VSC.Flux_laglead',...
            'VSC.IL2_d',...
            'VSC.IL2_q'};


        suffix = "_" + string(obj.ID);

        names = strcat(baseNames, suffix);

    end

end
end