% === main_simulacao_corrigido.m ===
clear; clc; close all;
addpath('utils');

%% Parâmetros de simulação ajustados
t0 = 6 * 3600;       % Início às 6h (em segundos)
tf = 30 * 3600;       % 24 horas de simulação (até 6h do dia seguinte)
Tinit = 23 + 273.15;  % Temperatura inicial em Kelvin

% Opções de integração mais conservadoras
options = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, 'MaxStep', 60, ...
                 'InitialStep', 1, 'MaxOrder', 2);

%% Inicialização com temperaturas iguais em Kelvin
Y0 = repmat(Tinit, 15, 1);

%% Execução da simulação com tratamento de erros
try
    disp('=== Simulação sistema térmico corrigido ===');
    tic;
    [t, Y] = ode45(@(t,Y) sistema_termico_total(t,Y), [t0 tf], Y0, options);
    tempo = toc;
    fprintf('Simulação concluída em %.2f s (%.2f min)\n', tempo, tempo / 60);

    % Verificação de resultados físicos
    if max(Y(:,1)) > 500 + 273.15
        warning('Temperaturas excederam limites físicos! Verifique o modelo.');
    end

catch ME
    fprintf('Erro durante a simulação: %s\n', ME.message);
    return;
end

%% Processamento dos resultados
amostragem = max(1, floor(length(t)/1000));  % Amostrar para ~1000 pontos
indices = 1:amostragem:length(t);
horas = t(indices) / 3600;

% Conversão para °C para visualização
Tmotor = Y(indices,1) - 273.15;
Tar_motor = Y(indices,2) - 273.15;
Tsensor_motor = Y(indices,5) - 273.15;
Tar_res = Y(indices,6) - 273.15;
Tsensor_res = Y(indices,7) - 273.15;
Tgerador = Y(indices,8) - 273.15;
Tbateria = Y(indices,9) - 273.15;
Tparede_leste = Y(indices,10) - 273.15;
Tparede_oeste = Y(indices,11) - 273.15;
Tparede_sul = Y(indices,12) - 273.15;
Tparede_teto = Y(indices,13) - 273.15;
Tparede_motor_int = Y(indices,14) - 273.15;
Tparede_res_ext = Y(indices,15) - 273.15;
T_amb = arrayfun(@(x) T_amb(x)-273.15, t(indices));

%% Visualização dos resultados
figure;
subplot(2,1,1);
plot(horas, Tmotor, 'r', horas, Tar_motor, 'b', horas, T_amb, 'k--', 'LineWidth', 1.5);
title('Temperaturas no Espaço do Motor');
xlabel('Hora do dia'); ylabel('Temperatura [°C]');
legend('Motor', 'Ar motor', 'T_{amb}', 'Location', 'best'); grid on;

subplot(2,1,2);
plot(horas, Tar_res, 'g', horas, Tparede_res_ext, 'm', horas, T_amb, 'k--', 'LineWidth', 1.5);
title('Temperaturas no Espaço do Reservatório');
xlabel('Hora do dia'); ylabel('Temperatura [°C]');
legend('Ar res.', 'Parede divisória', 'T_{amb}', 'Location', 'best'); grid on;

figure;
plot(horas, Tgerador, 'b', horas, Tbateria, 'k', 'LineWidth', 1.5);
title('Temperatura dos Componentes');
xlabel('Hora do dia'); ylabel('Temperatura [°C]');
legend('Gerador', 'Bateria', 'Location', 'best'); grid on;

%% Resultados numéricos
[temp_max_motor, idx_max] = max(Tmotor);
hora_max = horas(idx_max);
fprintf('\n=== RESULTADOS ===\n');
fprintf('Temperatura máxima do motor: %.2f °C às %.2f h\n', temp_max_motor, hora_max);
fprintf('Temperatura máxima do ar no motor: %.2f °C\n', max(Tar_motor));
fprintf('Temperatura máxima no reservatório: %.2f °C\n', max(Tar_res));
