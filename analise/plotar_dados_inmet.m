clear; clc; close all;

addpath('../utils');

% --- Função Auxiliar para Ler e Processar Ficheiros do INMET ---
function [hours_plot, radiation_plot] = process_inmet_data(filename, target_date_str)
    hours_plot = [];
    radiation_plot = [];

    try
        fid = fopen(filename, 'rt', 'n', 'latin1');
        if fid == -1, error('Não foi possível abrir o arquivo: %s', filename); end

        % Pula cabeçalho dinamicamente
        header_lines = 0;
        while header_lines < 10 % Limite para não entrar em loop infinito
            line = fgetl(fid);
              if ~isempty(strfind(line, 'Data;'))
                break;
            end
            header_lines = header_lines + 1;
        end

        data_inmet = {};
        expected_cols = 19;

        while ~feof(fid)
            line = fgetl(fid);
            if isempty(line) || ~ischar(line) || length(line) < 10, continue; end
            line_dot = strrep(line, ',', '.');
            split_line = strsplit(line_dot, ';');
            if ~isempty(split_line) && isempty(split_line{end}), split_line = split_line(1:end-1); end
            current_cols = length(split_line);
            if current_cols > expected_cols, split_line = split_line(1:expected_cols);
            elseif current_cols < expected_cols, split_line = [split_line, cell(1, expected_cols-current_cols)]; end
            data_inmet = [data_inmet; split_line];
        end
        fclose(fid);

        dates = data_inmet(:, 1);
        hours_utc_str = strrep(data_inmet(:, 2), ' UTC', '');
        hours_utc = str2double(hours_utc_str) / 100;
        radiation_kj = str2double(data_inmet(:, 7));

        idx_target_day = find(strcmp(dates, target_date_str));
        if isempty(idx_target_day), fprintf('AVISO: Nenhum dado encontrado para %s no ficheiro %s.\n', target_date_str, filename); return; end

        fprintf('Encontrados %d registos para a data %s.\n', length(idx_target_day), target_date_str);

        hours_day_utc = hours_utc(idx_target_day);
        radiation_kj_day = radiation_kj(idx_target_day);
        hours_day_local = hours_day_utc - 3;
        radiation_watt_day = (radiation_kj_day * 1000) / 3600;

        valid_idx = ~isnan(radiation_watt_day);
        hours_plot = hours_day_local(valid_idx);
        radiation_plot = radiation_watt_day(valid_idx);

    catch ME
        fprintf('Erro ao processar o ficheiro %s: %s\n', filename, ME.message);
    end
end

% --- Processamento dos Dados ---
fprintf('Lendo e tratando os dados do INMET para São Luís...\n');
[hours_2023, radiation_2023] = process_inmet_data('INMET_NE_MA_A203_SAO LUIS_01-01-2023_A_31-12-2023.CSV', '2023/09/22');
% Como 2024 é bissexto, o equinócio pode ser no dia 22 ou 23. Vamos procurar o dia 22.
[hours_2024, radiation_2024] = process_inmet_data('INMET_NE_MA_A203_SAO LUIS_01-01-2024_A_31-12-2024.CSV', '2024/09/22');

% --- Geração dos Dados do Modelo Teórico ---
p = parametros();
t_vec = linspace(0, 24*3600, 200);
horas_modelo = t_vec / 3600;
G_modelo_data = arrayfun(@(t) radiacao_solar(t, p), t_vec);
G_teto_modelo = [G_modelo_data.teto];

% --- Geração do Gráfico Comparativo ---
fig_comp = figure('Name', 'Comparativo: Radiação Real (INMET) vs. Modelo Teórico', 'NumberTitle', 'off');

plot(hours_2023, radiation_2023, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
hold on;
plot(hours_2024, radiation_2024, 'g-s', 'LineWidth', 2, 'MarkerFaceColor', 'g');
plot(horas_modelo, G_teto_modelo, 'r--', 'LineWidth', 2.5);
hold off;

title('Radiação Solar Global em São Luís - Comparativo Anual');
xlabel('Hora do Dia (Local)');
ylabel('Irradiância [W/m²]');
legend('Dados Reais INMET (2023)', 'Dados Reais INMET (2024)', 'Modelo Teórico ASHRAE', 'Location', 'north');
grid on;
ax = gca;
set(ax, 'XTick', 0:2:24);
set(ax, 'XMinorGrid', 'on');
set(ax, 'YMinorGrid', 'on');

% Salva o gráfico
if ~exist('../img', 'dir'), mkdir('../img'); end
print(fig_comp, '../img/Comparativo_INMET_MultiAno_vs_Modelo.png', '-dpng', '-r300');

fprintf('Gráfico comparativo salvo em "img/Comparativo_INMET_MultiAno_vs_Modelo.png".\n');

