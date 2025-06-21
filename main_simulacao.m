% === main_simulacao_m.m (Versão Final Completa) ===
% Script principal que executa a simulação, gera todos os gráficos de
% análise e apresenta um relatório automático dos resultados com base na
% questão do projeto selecionada no ficheiro de parâmetros.

clear; clc; close all;
addpath('utils');

%% Carrega os parâmetros e flags
p = parametros();

%% Parâmetros da Simulação e Condições Iniciais
t0 = 6 * 3600;
tf = 30 * 3600;
T_inicial_C = 23;
Tinit_K = T_inicial_C + 273.15;

Y0 = repmat(Tinit_K, 15, 1);
Y0(4) = p.m_res;

%% Configurações do Solver de EDO
options = odeset('RelTol', 1e-5, 'AbsTol', 1e-5, 'Stats', 'on');

%% Execução da Simulação
try
    disp('=== Iniciando simulação com modelo físico completo ===');
    tic;
    % CORREÇÃO: Passa 'p' e 'Tinit_K' como parâmetros para a função do sistema.
    [t, Y] = ode15s(@(t,Y) sistema_termico_total(t, Y, p, Tinit_K), [t0 tf], Y0, options);
    tempo_exec = toc;
    fprintf('Simulação concluída com sucesso em %.2f s (%.2f min).\n', tempo_exec, tempo_exec / 60);
catch ME
    fprintf('\nERRO DURANTE A SIMULAÇÃO: %s\n', ME.message);
    fprintf('Ficheiro: %s, Linha: %d\n', ME.stack(1).file, ME.stack(1).line);
    return;
end

%% Pós-processamento e Visualização
% (O resto do código de plotagem e análise permanece o mesmo)
horas = t / 3600;
T_motor_C = Y(:,1) - 273.15;
T_ar_motor_C = Y(:,2) - 273.15;
T_reservatorio_C = Y(:,3) - 273.15;
T_ar_res_C = Y(:,6) - 273.15;
T_parede_leste_C = Y(:,10) - 273.15;
T_parede_oeste_C = Y(:,11) - 273.15;
T_parede_sul_C = Y(:,12) - 273.15;
T_parede_teto_C = Y(:,13) - 273.15;
T_amb_C = arrayfun(@(x) T_amb(x) - 273.15, t);
G_data = arrayfun(@(x) radiacao_solar(x, p), t);
G_teto_vec = [G_data.teto];
G_leste_vec = [G_data.leste];
G_oeste_vec = [G_data.oeste];
G_sul_vec = [G_data.sul];

% (Secção de gráficos e análise final permanece a mesma)
figure('Name', 'Irradiância Solar Incidente (Causa)', 'NumberTitle', 'off');
plot(horas, G_teto_vec, 'Color', '#D95319', 'LineWidth', 2);
hold on;
plot(horas, G_leste_vec, 'Color', '#77AC30', 'LineWidth', 1.5, 'LineStyle', '--');
plot(horas, G_oeste_vec, 'Color', '#7E2F8E', 'LineWidth', 1.5, 'LineStyle', '--');
plot(horas, G_sul_vec, 'Color', '#A2142F', 'LineWidth', 1.5, 'LineStyle', ':');
hold off;
title('Irradiância Solar Incidente nas Superfícies (G)');
xlabel('Hora do Dia [h]'); ylabel('Irradiância [W/m²]');
legend('Teto', 'Parede Leste', 'Parede Oeste', 'Parede Sul', 'Location', 'north');
grid on; xlim([t0/3600, tf/3600]);

figure('Name', 'Temperaturas das Paredes Externas (Efeito)', 'NumberTitle', 'off');
plot(horas, T_parede_teto_C, 'Color', '#D95319', 'LineWidth', 2);
hold on;
plot(horas, T_parede_leste_C, 'Color', '#77AC30', 'LineWidth', 1.5);
plot(horas, T_parede_oeste_C, 'Color', '#7E2F8E', 'LineWidth', 1.5);
plot(horas, T_parede_sul_C, 'Color', '#A2142F', 'LineWidth', 1.5);
plot(horas, T_amb_C, 'k', 'LineWidth', 1, 'LineStyle', '--');
hold off;
title('Temperaturas das Paredes Externas');
xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
legend('Teto', 'Parede Leste', 'Parede Oeste', 'Parede Sul', 'Ambiente', 'Location', 'northwest');
grid on; xlim([t0/3600, tf/3600]);

figure('Name', 'Temperaturas Internas Principais', 'NumberTitle', 'off');
plot(horas, T_motor_C, 'r', 'LineWidth', 2);
hold on;
plot(horas, T_ar_motor_C, 'b--', 'LineWidth', 1.5);
plot(horas, T_reservatorio_C, 'g-.', 'LineWidth', 1.5);
plot(horas, T_ar_res_C, 'm:', 'LineWidth', 1.5);
plot(horas, T_amb_C, 'k', 'LineWidth', 1, 'LineStyle', '-.');
hold off;
title('Temperaturas Internas');
xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
legend('Motor', 'Ar (Motor)', 'Reservatório Diesel', 'Ar (Reservatório)', 'Ambiente', 'Location', 'northwest');
grid on; xlim([t0/3600, tf/3600]);

fprintf('\n\n========= ANÁLISE ESPECÍFICA DA SIMULAÇÃO =========\n');
if p.withVariablePower
    fprintf('MODO ATIVO: Questão 5 - Potência Variável\n');
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
elseif p.withOnOffControl
    fprintf('MODO ATIVO: Questão 4 - Controle On-Off\n');
    fprintf(' -> Análise da Questão 4 a ser implementada.\n');
elseif p.withFanFail
    fprintf('MODO ATIVO: Questão 3 - Falha da Ventoinha\n');
    [max_T_motor, ~] = max(T_motor_C);
    fprintf(' -> 3b) Temperatura Máxima do Motor (com falha da ventoinha): %.2f °C\n', max_T_motor);
elseif p.withExhaustorFail
     fprintf('MODO ATIVO: Questão 3d - Falha do Exaustor\n');
     [max_T_ar_res, ~] = max(T_ar_res_C);
     fprintf(' -> 3d) Temperatura Máxima do Ar no Reservatório: %.2f °C\n', max_T_ar_res);
else
    fprintf('MODO ATIVO: Questão 2 - Potência Fixa (Cenário Base)\n');
    idx_18h = find(t >= 18*3600, 1, 'first');
    fprintf(' -> 2d) Temperatura do Motor às 18h: %.2f °C\n', T_motor_C(idx_18h));
    fprintf(' -> 2d) Temperatura do Ar (Motor) às 18h: %.2f °C\n', T_ar_motor_C(idx_18h));
    fprintf(' -> 2d) Temperatura do Teto às 18h: %.2f °C\n', T_parede_teto_C(idx_18h));
end
fprintf('====================================================\n');

