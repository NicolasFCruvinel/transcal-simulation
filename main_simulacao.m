% === main_simulacao_final.m ===
% Script principal com visualização aprimorada para incluir o efeito
% da radiação solar nas paredes externas.

clear; clc; close all;
addpath('utils');

%% Parâmetros da Simulação
t0 = 6 * 3600;
tf = 30 * 3600;
T_inicial_C = 23;
Tinit_K = T_inicial_C + 273.15;

%% Configurações do Solver de EDO
options = odeset('RelTol', 1e-5, 'AbsTol', 1e-5, 'Stats', 'on');

%% Condições Iniciais
Y0 = repmat(Tinit_K, 15, 1);

%% Execução da Simulação
try
    disp('=== Iniciando simulação com modelo completo (incluindo radiação solar) ===');
    tic;
    [t, Y] = ode15s(@(t,Y) sistema_termico_total(t,Y), [t0 tf], Y0, options);
    tempo_exec = toc;
    fprintf('Simulação concluída com sucesso em %.2f s (%.2f min).\n', tempo_exec, tempo_exec / 60);
catch ME
    fprintf('\nERRO DURANTE A SIMULAÇÃO: %s\n', ME.message);
    return;
end

%% Pós-processamento e Visualização

% Conversão para °C
horas = t / 3600;
T_motor_C = Y(:,1) - 273.15;
T_ar_motor_C = Y(:,2) - 273.15;
T_ar_res_C = Y(:,6) - 273.15;
T_parede_leste_C = Y(:,10) - 273.15; % <-- NOVO
T_parede_oeste_C = Y(:,11) - 273.15; % <-- NOVO
T_parede_sul_C = Y(:,12) - 273.15;   % <-- NOVO
T_parede_teto_C = Y(:,13) - 273.15;  % <-- NOVO
T_amb_C = arrayfun(@(x) T_amb(x) - 273.15, t);

%% Gráficos dos Resultados

% Figura 1: Temperaturas Internas
figure('Name', 'Temperaturas Internas Principais', 'NumberTitle', 'off');
plot(horas, T_motor_C, 'r', 'LineWidth', 2);
hold on;
plot(horas, T_ar_motor_C, 'b--', 'LineWidth', 1.5);
plot(horas, T_ar_res_C, 'm:', 'LineWidth', 1.5);
plot(horas, T_amb_C, 'k', 'LineWidth', 1, 'LineStyle', '-.');
hold off;
title('Temperaturas Internas (Motor e Ar)');
xlabel('Hora do Dia');
ylabel('Temperatura (°C)');
legend('Motor', 'Ar (Motor)', 'Ar (Reservatório)', 'Ambiente', 'Location', 'northwest');
grid on;
xlim([t0/3600, tf/3600]);

% Figura 2: Temperaturas das Paredes Externas (EFEITO SOLAR)
figure('Name', 'Temperaturas das Paredes Externas', 'NumberTitle', 'off');
plot(horas, T_parede_teto_C, 'Color', '#D95319', 'LineWidth', 2); % Laranja
hold on;
plot(horas, T_parede_leste_C, 'Color', '#77AC30', 'LineWidth', 1.5); % Verde
plot(horas, T_parede_oeste_C, 'Color', '#7E2F8E', 'LineWidth', 1.5); % Roxo
plot(horas, T_parede_sul_C, 'Color', '#A2142F', 'LineWidth', 1.5);  % Vermelho escuro
plot(horas, T_amb_C, 'k', 'LineWidth', 1, 'LineStyle', '--');
hold off;
title('Efeito da Radiação Solar nas Paredes Externas');
xlabel('Hora do Dia');
ylabel('Temperatura (°C)');
legend('Teto', 'Parede Leste (sol de manhã)', 'Parede Oeste (sol de tarde)', 'Parede Sul', 'Ambiente', 'Location', 'northwest');
grid on;
xlim([t0/3600, tf/3600]);

%% Apresentação dos Resultados Numéricos
[temp_max_motor, idx_max_motor] = max(T_motor_C);
hora_max_motor = horas(idx_max_motor);
fprintf('\n========= RESULTADOS FINAIS =========\n');
fprintf('Temperatura Máxima do Motor: %.2f °C (às %.2f h).\n', temp_max_motor, hora_max_motor);
fprintf('====================================\n');

