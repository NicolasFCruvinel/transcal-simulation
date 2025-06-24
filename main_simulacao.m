clear; clc; close all;
addpath('utils');

%% Carrega os parâmetros e flags
p = parametros();

%% Parâmetros da Simulação e Condições Iniciais
t0 = 6 * 3600;
tf = 30 * 3600;
T_inicial_C = 23;
Tinit_K = T_inicial_C + 273.15;

Y0 = repmat(Tinit_K, 19, 1); % VETOR EXPANDIDO PARA 19 ESTADOS
Y0(4) = p.m_res;             % Define a massa inicial do reservatório

%% Configurações do Solver de EDO
options = odeset('RelTol', 1e-5, 'AbsTol', 1e-5, 'Stats', 'on');

%% Execução da Simulação
try
    disp('=== Iniciando simulação com modelo físico completo ===');
    tic;
    [t, Y] = ode15s(@(t,Y) sistema_termico_total(t, Y, p, Tinit_K), [t0 tf], Y0, options);
    tempo_exec = toc;
    fprintf('Simulação concluída com sucesso em %.2f s (%.2f min).\n', tempo_exec, tempo_exec / 60);
catch ME
    fprintf('\nERRO DURANTE A SIMULAÇÃO: %s\n', ME.message);
    fprintf('Ficheiro: %s, Linha: %d\n', ME.stack(1).file, ME.stack(1).line);
    return;
end

%% Pós-processamento e Extração de Dados
horas = t / 3600;
T_motor_C = Y(:,1) - 273.15;
T_ar_motor_C = Y(:,2) - 273.15;
T_reservatorio_C = Y(:,3) - 273.15;
Tsensor_motor_C = Y(:,5) - 273.15;
T_ar_res_C = Y(:,6) - 273.15;
T_parede_leste_motor_C = Y(:,10) - 273.15;
T_parede_oeste_motor_C = Y(:,11) - 273.15;
T_parede_sul_motor_C = Y(:,12) - 273.15;
T_parede_teto_motor_C = Y(:,13) - 273.15;
T_parede_motor_int_C = Y(:,14) - 273.15;
T_parede_res_ext_C = Y(:,15) - 273.15;
T_parede_norte_res_C = Y(:,16) - 273.15;
T_parede_leste_res_C = Y(:,17) - 273.15;
T_parede_oeste_res_C = Y(:,18) - 273.15;
T_parede_teto_res_C = Y(:,19) - 273.15;
T_amb_C = arrayfun(@(x) T_amb(x) - 273.15, t);
G_data = arrayfun(@(x) radiacao_solar(x, p), t);
G_teto_vec = [G_data.teto]; G_leste_vec = [G_data.leste];
G_oeste_vec = [G_data.oeste]; G_sul_vec = [G_data.sul];

%% Geração de Gráficos Organizados com Grelha Fina e Salvamento Automático

% --- Cria o diretório para salvar as imagens ---
if ~exist('img', 'dir')
   mkdir('img');
end

% --- Define o prefixo do nome do ficheiro com base na questão ---
filename_prefix = 'Q2_PotenciaFixa_'; % Padrão para a Questão 2
if p.withOnOffControl
    filename_prefix = 'Q4_ControleOnOff_';
elseif p.withVariablePower
    filename_prefix = 'Q5_PotenciaVariavel_';
elseif p.withFanFail
    filename_prefix = 'Q3_FalhaVentoinha_';
elseif p.withExhaustorFail
     filename_prefix = 'Q3d_FalhaExaustor_';
end

% Função auxiliar para configurar a grelha
function configure_grid(x_step, y_step, t0_sec, tf_sec)
    ax = gca;
    y_limits = get(ax, 'YLim');
    x_ticks = (t0_sec/3600):x_step:(tf_sec/3600);
    y_ticks = floor(min(y_limits)/y_step)*y_step : y_step : ceil(max(y_limits)/y_step)*y_step;

    set(ax, 'XTick', x_ticks);
    set(ax, 'YTick', y_ticks);
    set(ax, 'XMinorGrid', 'on');
    set(ax, 'YMinorGrid', 'on');
    grid on;
end

% Figura 1: Irradiância Solar (A Causa)
fig1 = figure('Name', 'Irradiância Solar Incidente', 'NumberTitle', 'off');
plot(horas, G_teto_vec, 'Color', '#D95319', 'LineWidth', 2); hold on;
plot(horas, G_leste_vec, 'Color', '#77AC30', 'LineWidth', 1.5, 'LineStyle', '--');
plot(horas, G_oeste_vec, 'Color', '#7E2F8E', 'LineWidth', 1.5, 'LineStyle', '--');
plot(horas, G_sul_vec, 'Color', '#A2142F', 'LineWidth', 1.5, 'LineStyle', ':'); hold off;
title('Irradiância Solar Incidente nas Superfícies (G)');
xlabel('Hora do Dia [h]'); ylabel('Irradiância [W/m²]');
legend('Teto', 'Parede Leste', 'Parede Oeste', 'Parede Sul', 'Location', 'north');
xlim([t0/3600, tf/3600]);
configure_grid(1, 100, t0, tf);
set(fig1, 'PaperUnits', 'inches'); set(fig1, 'PaperPosition', [0 0 16 9]);
print(fig1, ['img/' filename_prefix '1_irradiancia_solar.png'], '-dpng', '-r300');

% Figura 2: Temperaturas das Paredes (Lado do Motor)
fig2 = figure('Name', 'Temperaturas das Paredes - Lado Motor', 'NumberTitle', 'off');
plot(horas, T_parede_teto_motor_C, 'Color', '#D95319', 'LineWidth', 2); hold on;
plot(horas, T_parede_leste_motor_C, 'Color', '#77AC30', 'LineWidth', 1.5);
plot(horas, T_parede_oeste_motor_C, 'Color', '#7E2F8E', 'LineWidth', 1.5);
plot(horas, T_parede_sul_motor_C, 'Color', '#A2142F', 'LineWidth', 1.5);
plot(horas, T_amb_C, 'k', 'LineWidth', 1, 'LineStyle', '--'); hold off;
title('Temperaturas das Paredes Externas (Lado do Motor)');
xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
legend('Teto', 'Parede Leste', 'Parede Oeste', 'Parede Sul', 'Ambiente', 'Location', 'northwest');
xlim([t0/3600, tf/3600]);
configure_grid(1, 5, t0, tf);
set(fig2, 'PaperUnits', 'inches'); set(fig2, 'PaperPosition', [0 0 16 9]);
print(fig2, ['img/' filename_prefix '2_paredes_motor.png'], '-dpng', '-r300');

% Figura 3: Temperaturas das Paredes (Lado do Reservatório)
fig3 = figure('Name', 'Temperaturas das Paredes - Lado Reservatório', 'NumberTitle', 'off');
plot(horas, T_parede_norte_res_C, 'b', 'LineWidth', 1.5); hold on;
plot(horas, T_parede_leste_res_C, 'g', 'LineWidth', 1.5);
plot(horas, T_parede_oeste_res_C, 'r', 'LineWidth', 1.5);
plot(horas, T_parede_teto_res_C, 'c', 'LineWidth', 2);
plot(horas, T_amb_C, 'k', 'LineWidth', 1, 'LineStyle', '--'); hold off;
title('Temperaturas das Paredes Externas (Lado do Reservatório)');
xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
legend('Parede Norte', 'Parede Leste', 'Parede Oeste', 'Teto', 'Ambiente', 'Location', 'northwest');
xlim([t0/3600, tf/3600]);
configure_grid(1, 5, t0, tf);
set(fig3, 'PaperUnits', 'inches'); set(fig3, 'PaperPosition', [0 0 16 9]);
print(fig3, ['img/' filename_prefix '3_paredes_reservatorio.png'], '-dpng', '-r300');

% Figura 4: Temperaturas Internas (Lado do Motor)
fig4 = figure('Name', 'Temperaturas Internas - Lado Motor', 'NumberTitle', 'off');
plot(horas, T_motor_C, 'r', 'LineWidth', 2); hold on;
plot(horas, T_ar_motor_C, 'b--', 'LineWidth', 1.5);
plot(horas, T_parede_motor_int_C, 'Color', [0.4660 0.6740 0.1880], 'LineStyle', '-.', 'LineWidth', 1.5);
plot(horas, T_amb_C, 'k:', 'LineWidth', 1.5); hold off;
title('Temperaturas Internas do Compartimento do Motor');
xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
legend('Motor', 'Ar do Motor', 'Parede Divisória (Lado Motor)', 'Ambiente', 'Location', 'northwest');
xlim([t0/3600, tf/3600]);
configure_grid(1, 10, t0, tf);
set(fig4, 'PaperUnits', 'inches'); set(fig4, 'PaperPosition', [0 0 16 9]);
print(fig4, ['img/' filename_prefix '4_internas_motor.png'], '-dpng', '-r300');

% Figura 5: Temperaturas Internas (Lado do Reservatório)
fig5 = figure('Name', 'Temperaturas Internas - Lado Reservatório', 'NumberTitle', 'off');
plot(horas, T_reservatorio_C, 'g', 'LineWidth', 2); hold on;
plot(horas, T_ar_res_C, 'm--', 'LineWidth', 1.5);
plot(horas, T_parede_res_ext_C, 'Color', [0.9290 0.6940 0.1250], 'LineStyle', '-.', 'LineWidth', 1.5);
plot(horas, T_amb_C, 'k:', 'LineWidth', 1.5); hold off;
title('Temperaturas Internas do Compartimento do Reservatório');
xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
legend('Reservatório Diesel', 'Ar do Reservatório', 'Parede Divisória (Lado Res.)', 'Ambiente', 'Location', 'northwest');
xlim([t0/3600, tf/3600]);
configure_grid(1, 2, t0, tf);
set(fig5, 'PaperUnits', 'inches'); set(fig5, 'PaperPosition', [0 0 16 9]);
print(fig5, ['img/' filename_prefix '5_internas_reservatorio.png'], '-dpng', '-r300');

% Figura 6: Visão Geral das Temperaturas Internas
fig6 = figure('Name', 'Visão Geral das Temperaturas Internas', 'NumberTitle', 'off');
plot(horas, T_motor_C, 'r', 'LineWidth', 2); hold on;
plot(horas, T_ar_motor_C, 'b--', 'LineWidth', 1.5);
plot(horas, T_parede_motor_int_C, 'Color', [0.4660 0.6740 0.1880], 'LineStyle', '-.', 'LineWidth', 1.5);
plot(horas, T_reservatorio_C, 'g', 'LineWidth', 2);
plot(horas, T_ar_res_C, 'm--', 'LineWidth', 1.5);
plot(horas, T_parede_res_ext_C, 'Color', [0.9290 0.6940 0.1250], 'LineStyle', '-.', 'LineWidth', 1.5);
plot(horas, T_amb_C, 'k:', 'LineWidth', 1.5); hold off;
title('Visão Geral de Todas as Temperaturas Internas');
xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
legend('Motor', 'Ar (Motor)', 'Parede Div. (Lado Motor)', 'Reservatório', 'Ar (Reservatório)', 'Parede Div. (Lado Res.)', 'Ambiente', 'Location', 'northwest');
xlim([t0/3600, tf/3600]);
configure_grid(1, 10, t0, tf);
set(fig6, 'PaperUnits', 'inches'); set(fig6, 'PaperPosition', [0 0 16 9]);
print(fig6, ['img/' filename_prefix '6_internas_geral.png'], '-dpng', '-r300');

%% ANÁLISE ESPECÍFICA POR QUESTÃO
fprintf('\n\n========= ANÁLISE ESPECÍFICA DA SIMULAÇÃO: %s =========\n', strrep(filename_prefix(1:end-1), '_', ' '));
if p.withOnOffControl
    T_on = 100; T_off = 80;
    rad_state = zeros(size(t)); current_state = false;
    for i=1:length(t)
        if Tsensor_motor_C(i) >= T_on, current_state = true; end
        if Tsensor_motor_C(i) <= T_off, current_state = false; end
        rad_state(i) = current_state;
    end
    on_events_idx = find(diff(rad_state) > 0) + 1;
    if length(on_events_idx) > 9
        t_on_cycle_9 = t(on_events_idx(9));
        t_on_cycle_10 = t(on_events_idx(10));
        intervalo_s = t_on_cycle_10 - t_on_cycle_9;
        idx_start = on_events_idx(9);
        idx_end = on_events_idx(10);
        T_ar_cycle = T_ar_motor_C(idx_start:idx_end);
        delta_T_ar = max(T_ar_cycle) - min(T_ar_cycle);
        fprintf(' -> 4b) Intervalo do ciclo liga/desliga (após 8 ciclos): %.2f s (ou %.2f min)\n', intervalo_s, intervalo_s/60);
        fprintf(' -> 4c) Variação máxima de temp. do ar no ciclo: %.2f °C\n', delta_T_ar);
    else
        fprintf(' -> Não foram detectados ciclos suficientes para a análise (detectados %d).\n', length(on_events_idx));
    end
elseif p.withVariablePower
    [max_T_motor, ~] = max(T_motor_C); [max_T_ar_motor, ~] = max(T_ar_motor_C);
    fprintf(' -> 5b) Temperatura Máxima do Motor: %.2f °C\n', max_T_motor);
    fprintf(' -> 5b) Temperatura Máxima do Ar (Motor): %.2f °C\n', max_T_ar_motor);
    Pel_vec = arrayfun(@power_profile, t);
    idx_operacao = find(Pel_vec > 0); t_operacao = t(idx_operacao); Pel_operacao = Pel_vec(idx_operacao);
    eta_motor = 0.3; eta_gerador = 0.9;
    P_comb_operacao = Pel_operacao / (eta_motor * eta_gerador);
    Energia_comb_J = trapz(t_operacao, P_comb_operacao); Energia_eletrica_J = trapz(t_operacao, Pel_operacao);
    massa_comb_kg = (Energia_comb_J / 1000) / p.poder_calorifico_diesel;
    volume_L = (massa_comb_kg / p.densidade_diesel) * 1000;
    Energia_eletrica_kWh = Energia_eletrica_J / (3600 * 1000);
    fprintf(' -> 5c) Consumo de Combustível Total: %.2f Litros\n', volume_L);
    fprintf(' -> 5c) Energia Elétrica Gerada: %.2f kWh\n', Energia_eletrica_kWh);
elseif p.withFanFail
    [max_T_motor, ~] = max(T_motor_C);
    fprintf(' -> 3b) Temperatura Máxima do Motor (com falha da ventoinha): %.2f °C\n', max_T_motor);
elseif p.withExhaustorFail
     [max_T_ar_res, ~] = max(T_ar_res_C);
     fprintf(' -> 3d) Temperatura Máxima do Ar no Reservatório: %.2f °C\n', max_T_ar_res);
else
    idx_18h = find(t >= 18*3600, 1, 'first');
    fprintf(' -> 2d) Temperatura do Motor às 18h: %.2f °C\n', T_motor_C(idx_18h));
    fprintf(' -> 2d) Temperatura do Ar (Motor) às 18h: %.2f °C\n', T_ar_motor_C(idx_18h));
    fprintf(' -> 2d) Temperatura do Teto às 18h: %.2f °C\n', T_parede_teto_motor_C(idx_18h));
end
fprintf('====================================================\n');

