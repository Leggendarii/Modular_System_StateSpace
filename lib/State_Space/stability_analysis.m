function stability_analysis(ss_system)
% STABILITY_ANALYSIS
% Complete modal analysis with robust participation-factor computation.
%
% Improvements:
% - Consistent eigenvalue ordering
% - Exact biorthogonal normalization (W'*V = I)
% - Participation factors independent of eig() mode ordering
% - More robust numerical handling
%
% Author: Nicolae Darii

%% ============================================================
% 1. INPUT VALIDATION
% =============================================================
n_states = size(ss_system.A,1);

if isempty(ss_system.StateName)
    warning('StateName property missing. Using generic labels.');
    ss_system.StateName = arrayfun(@(i) sprintf('State_%d',i), ...
        1:n_states,'UniformOutput',false)';
end

stateNames = ss_system.StateName(:);

%% ============================================================
% 2. EIGENANALYSIS
% =============================================================
A = ss_system.A;

[V,D] = eig(A);
lambda = diag(D);

% Consistent sorting of modes
[~,idx_modes] = sortrows([real(lambda) imag(lambda)]);  % Eigenvalues non sono sempre in ordine una volta calcolati!

lambda = lambda(idx_modes);
V = V(:,idx_modes);

%% ============================================================
% 3. LEFT EIGENVECTORS + BIORTHOGONALIZATION
% =============================================================
[W,~] = eig(A.');

W = conj(W);
W = W(:,idx_modes);

% Enforce W'*V = I
M = W.'*V;
W = W/M;

%% ============================================================
% 4. MODAL QUANTITIES
% =============================================================
wn = abs(lambda);

zeta = zeros(size(lambda));

idx_nonzero = wn > 1e-12;
zeta(idx_nonzero) = ...
    -real(lambda(idx_nonzero))./wn(idx_nonzero)*100;

freq_Hz = abs(imag(lambda))/(2*pi);

%% ============================================================
% 5. PARTICIPATION FACTOR MATRIX
% =============================================================
PF = abs(W.*V);

% Normalize each mode to 100%
PF_percent = zeros(size(PF));

for k = 1:length(lambda)

    denom = sum(PF(:,k));

    if denom > 0
        PF_percent(:,k) = 100*PF(:,k)/denom;
    end

end

%% ============================================================
% 6. CRITICAL MODE
% =============================================================
stable_modes = real(lambda) < 0;

if any(stable_modes)

    zeta_search = zeta;
    zeta_search(~stable_modes) = inf;

    [zeta_min,k] = min(zeta_search);

else

    k = find(real(lambda)>=0,1);
    zeta_min = zeta(k);

end

p_k = PF(:,k);
perc_p = PF_percent(:,k);

[~,idx_sorted] = sort(p_k,'descend');

%% ============================================================
% 7. TABLES
% =============================================================
PF_critical = table( ...
    stateNames(idx_sorted), ...
    repmat(zeta_min,n_states,1), ...
    repmat(freq_Hz(k),n_states,1), ...
    p_k(idx_sorted), ...
    perc_p(idx_sorted), ...
    'VariableNames', ...
    {'State','Damping_%','Frequency_Hz', ...
     'PartAbs','PartPercent'});

eigTable = table( ...
    (1:length(lambda))', ...
    lambda, ...
    real(lambda), ...
    imag(lambda), ...
    freq_Hz, ...
    zeta, ...
    'VariableNames', ...
    {'Mode','Eigenvalue','RealPart', ...
    'ImagPart','Frequency_Hz','Damping_%'});

%% ============================================================
% 8. PLOTS
% =============================================================
figure('Name','Complete Modal Analysis',...
       'NumberTitle','off');

pzmap(ss_system);
hold on;
grid on;
sgrid;

if all(real(lambda)<0)
    stability_str = 'STABLE';
    stability_color = [0 0.6 0];
else
    stability_str = 'UNSTABLE';
    stability_color = [1 0 0];
end

lambda_crit = lambda(k);

plot(real(lambda_crit),imag(lambda_crit), ...
    'ro', ...
    'MarkerSize',14, ...
    'MarkerFaceColor',stability_color, ...
    'LineWidth',3);

text(real(lambda_crit)+0.02,...
     imag(lambda_crit),...
     sprintf('Mode %d\n\\zeta = %.2f%%',k,zeta_min),...
     'FontSize',11,...
     'FontWeight','bold',...
     'BackgroundColor','w');

title(sprintf('Modal Analysis (n=%d)',n_states));

xlabel('Real Part [rad/s]');
ylabel('Imag Part [rad/s]');

hold off;

%% ============================================================
% 9. CONSOLE OUTPUT
% =============================================================
fprintf('\n');
fprintf('====================================================\n');
fprintf(' COMPLETE MODAL ANALYSIS\n');
fprintf('====================================================\n');

fprintf('System order : %d states\n',n_states);
fprintf('Critical mode: %d\n',k);
fprintf('Damping      : %.3f %%\n',zeta_min);
fprintf('Frequency    : %.3f Hz\n',freq_Hz(k));

fprintf('\n');
fprintf('CRITICAL MODE PARTICIPATION FACTORS\n');
fprintf('-----------------------------------\n');
disp(PF_critical);

fprintf('\n');
fprintf('EIGENVALUE SPECTRUM\n');
fprintf('-------------------\n');
disp(eigTable);

stato_dominante = stateNames{idx_sorted(1)};
perc_dominante = perc_p(idx_sorted(1));

fprintf('\n');
fprintf('SUMMARY\n');
fprintf('-------\n');
fprintf('%s | Critical damping %.2f %%\n', ...
    stability_str,zeta_min);

fprintf('Dominant state: %s (%.1f%%)\n', ...
    stato_dominante,perc_dominante);

%% ============================================================
% 10. FULL PARTICIPATION FACTOR MATRIX
% =============================================================
PF_table = array2table(PF_percent,...
    'RowNames',stateNames);

PF_table.Properties.VariableNames = ...
    compose('Mode_%d',1:length(lambda));

figPF = uifigure( ...
    'Name','Participation Factor Matrix', ...
    'Position',[100 100 1600 800]);

uit = uitable(figPF,...
    'Data',PF_table,...
    'Position',[10 10 1580 780]);

data = PF_percent;

maxVal = max(data(:));

% Stato dominante del modo critico
[~,dom_state_idx] = max(data(:,k));

for r = 1:size(data,1)

    for c = 1:size(data,2)

        % Grigio: 0% -> quasi bianco, max PF -> grigio scuro
        gray = 0.95 - 0.65*(data(r,c)/maxVal);

        if r == dom_state_idx && c == k

            % PF dominante del modo meno smorzato
            s = uistyle( ...
                'BackgroundColor',[gray gray gray], ...
                'FontWeight','bold');

        else

            s = uistyle( ...
                'BackgroundColor',[gray gray gray]);

        end

        addStyle(uit,s,'cell',[r c]);

    end

end

end