% === main_simulacao.m (Versão Final Completa) ===
% Script principal que executa a simulação, gera gráficos completos e
% calcula todos os valores necessários para o relatório final.

clear; clc; close all;
addpath('utils');

%% Carrega os parâmetros e flags
p = parametros();

%% Parâmetros da Simulação e Condições Iniciais
t0 = 6 * 3600;
tf = 30 * 3600;
T_inicial_C = 23;
Tinit_K = T_inicial_C + 273.15;

Y0 = repmat(Tinit_K, 21, 1);
Y0(4) = p.m_res;

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
Tsensor_res_C = Y(:,7) - 273.15;
T_gerador_C = Y(:,8) - 273.15;
T_bateria_C = Y(:,9) - 273.15;
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
T_chao_motor_C = Y(:,20) - 273.15;
T_chao_reserv_C = Y(:,21) - 273.15;
T_amb_C = arrayfun(@(x) T_amb(x) - 273.15, t);
G_data = arrayfun(@(x) radiacao_solar(x, p), t);
G_teto_vec = [G_data.teto]; G_leste_vec = [G_data.leste];
G_oeste_vec = [G_data.oeste]; G_sul_vec = [G_data.sul];

%% Geração de Gráficos (Controlada por Flag)

% Altere para 'if 1' para gerar e salvar todos os gráficos.
% Altere para 'if 0' para desativar a geração de gráficos.
if 1

    % --- Cria o diretório para salvar as imagens ---
    if ~exist('img', 'dir'), mkdir('img'); end

    % --- Define o prefixo do nome do ficheiro com base na questão ---
    filename_prefix = 'Q2_PotenciaFixa_';
    if p.withOnOffControl, filename_prefix = 'Q4_ControleOnOff_Ciclo_2_';
    elseif p.withVariablePower, filename_prefix = 'Q5_PotenciaVariavel_';
    elseif 0 %p.withFanFail, filename_prefix = 'Q3_FalhaVentoinha_';
    elseif p.withExhaustorFail, filename_prefix = 'Q3d_FalhaExaustor_'; end

    % Função auxiliar para configurar a grelha
    function configure_grid(x_step, y_step, t0_sec, tf_sec)
        ax = gca;
        y_limits = get(ax, 'YLim');
        x_ticks = (t0_sec/3600):x_step:(tf_sec/3600);
        y_ticks = floor(min(y_limits)/y_step)*y_step : y_step : ceil(max(y_limits)/y_step)*y_step;
        set(ax, 'XTick', x_ticks); set(ax, 'YTick', y_ticks);
        grid on; grid minor;
    end

    % --- PLOTAGEM DOS GRÁFICOS ---

    % Figura 1: Irradiância Solar
    fig1 = figure('Name', 'Irradiância Solar Incidente', 'NumberTitle', 'off');
    plot(horas, G_teto_vec, 'Color', '#D95319', 'LineWidth', 2); hold on;
    plot(horas, G_leste_vec, 'Color', '#77AC30', 'LineWidth', 1.5, 'LineStyle', '--');
    plot(horas, G_oeste_vec, 'Color', '#7E2F8E', 'LineWidth', 1.5, 'LineStyle', '--');
    plot(horas, G_sul_vec, 'Color', '#A2142F', 'LineWidth', 1.5, 'LineStyle', ':'); hold off;
    title('Irradiância Solar Incidente nas Superfícies (G)'); xlabel('Hora do Dia [h]'); ylabel('Irradiância [W/m²]');
    legend('Teto', 'Parede Leste', 'Parede Oeste', 'Parede Sul', 'Location', 'north');
    xlim([t0/3600, tf/3600]); configure_grid(1, 100, t0, tf);
    set(fig1, 'PaperUnits', 'inches'); set(fig1, 'PaperPosition', [0 0 16 9]);
    print(fig1, ['img/' filename_prefix '1_irradiancia_solar.png'], '-dpng', '-r300');

    % Figura 2: Paredes do Motor
    fig2 = figure('Name', 'Temperaturas das Paredes - Lado Motor', 'NumberTitle', 'off');
    plot(horas, T_parede_teto_motor_C, 'Color', '#D95319', 'LineWidth', 2); hold on;
    plot(horas, T_parede_leste_motor_C, 'Color', '#77AC30', 'LineWidth', 1.5);
    plot(horas, T_parede_oeste_motor_C, 'Color', '#7E2F8E', 'LineWidth', 1.5);
    plot(horas, T_parede_sul_motor_C, 'Color', '#A2142F', 'LineWidth', 1.5);
    plot(horas, T_chao_motor_C, 'Color', [0.5 0.5 0.5], 'LineWidth', 2);
    plot(horas, T_amb_C, 'k', 'LineWidth', 1, 'LineStyle', '--'); hold off;
    title('Temperaturas das Superfícies (Lado do Motor)'); xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
    legend('Teto', 'Parede Leste', 'Parede Oeste', 'Parede Sul', 'Chão', 'Ambiente', 'Location', 'northwest');
    xlim([t0/3600, tf/3600]); configure_grid(1, 5, t0, tf);
    set(fig2, 'PaperUnits', 'inches'); set(fig2, 'PaperPosition', [0 0 16 9]);
    print(fig2, ['img/' filename_prefix '2_paredes_motor.png'], '-dpng', '-r300');

    % Figura 3: Paredes do Reservatório
    fig3 = figure('Name', 'Temperaturas das Paredes - Lado Reservatório', 'NumberTitle', 'off');
    plot(horas, T_parede_norte_res_C, 'b', 'LineWidth', 1.5); hold on;
    plot(horas, T_parede_leste_res_C, 'g', 'LineWidth', 1.5);
    plot(horas, T_parede_oeste_res_C, 'r', 'LineWidth', 1.5);
    plot(horas, T_parede_teto_res_C, 'c', 'LineWidth', 2);
    plot(horas, T_chao_reserv_C, 'Color', [0.5 0.5 0.5], 'LineWidth', 2);
    plot(horas, T_amb_C, 'k', 'LineWidth', 1, 'LineStyle', '--'); hold off;
    title('Temperaturas das Superfícies (Lado do Reservatório)'); xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
    legend('Parede Norte', 'Parede Leste', 'Parede Oeste', 'Teto', 'Chão', 'Ambiente', 'Location', 'northwest');
    xlim([t0/3600, tf/3600]); configure_grid(1, 5, t0, tf);
    set(fig3, 'PaperUnits', 'inches'); set(fig3, 'PaperPosition', [0 0 16 9]);
    print(fig3, ['img/' filename_prefix '3_paredes_reservatorio.png'], '-dpng', '-r300');

    % Figura 4: Internas do Motor
    fig4 = figure('Name', 'Temperaturas Internas - Lado Motor', 'NumberTitle', 'off');
    plot(horas, T_motor_C, 'r', 'LineWidth', 2.5); hold on;
    plot(horas, Tsensor_motor_C, 'Color', [0.8500 0.3250 0.0980], 'LineStyle', ':', 'LineWidth', 2);
    plot(horas, T_ar_motor_C, 'b--', 'LineWidth', 1.5);
    plot(horas, T_gerador_C, 'Color', [0.4940 0.1840 0.5560], 'LineWidth', 1.5);
    plot(horas, T_bateria_C, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.5);
    plot(horas, T_parede_motor_int_C, 'Color', [0.6350 0.0780 0.1840], 'LineStyle', '-.');
    plot(horas, T_amb_C, 'k:', 'LineWidth', 1.5); hold off;
    title('Temperaturas Internas do Compartimento do Motor'); xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
    legend('Motor', 'Sensor Motor', 'Ar', 'Gerador', 'Bateria', 'Parede Divisória', 'Ambiente', 'Location', 'northwest');
    xlim([t0/3600, tf/3600]); configure_grid(1, 10, t0, tf);
    set(fig4, 'PaperUnits', 'inches'); set(fig4, 'PaperPosition', [0 0 16 9]);
    print(fig4, ['img/' filename_prefix '4_internas_motor.png'], '-dpng', '-r300');

    % Figura 5: Internas do Reservatório
    fig5 = figure('Name', 'Temperaturas Internas - Lado Reservatório', 'NumberTitle', 'off');
    plot(horas, T_reservatorio_C, 'g', 'LineWidth', 2.5); hold on;
    plot(horas, Tsensor_res_C, 'Color', [0.3010 0.7450 0.9330], 'LineStyle', ':', 'LineWidth', 2);
    plot(horas, T_ar_res_C, 'm--', 'LineWidth', 1.5);
    plot(horas, T_parede_res_ext_C, 'Color', [0.9290 0.6940 0.1250], 'LineStyle', '-.');
    plot(horas, T_amb_C, 'k:', 'LineWidth', 1.5); hold off;
    title('Temperaturas Internas do Compartimento do Reservatório'); xlabel('Hora do Dia [h]'); ylabel('Temperatura [°C]');
    legend('Reservatório', 'Sensor Ar', 'Ar', 'Parede Divisória', 'Ambiente', 'Location', 'northwest');
    xlim([t0/3600, tf/3600]); configure_grid(1, 2, t0, tf);
    set(fig5, 'PaperUnits', 'inches'); set(fig5, 'PaperPosition', [0 0 16 9]);
    print(fig5, ['img/' filename_prefix '5_internas_reservatorio.png'], '-dpng', '-r300');

end

%% ANÁLISE PARA RELATÓRIO
fprintf('\n\n========= ANÁLISE PARA RELATÓRIO =========\n');
if ~any([p.withFanFail, p.withExhaustorFail, p.withOnOffControl, p.withVariablePower])
    fprintf('MODO ATIVO: Questão 2 - Potência Fixa (Cenário Base)\n');
    idx_18h=find(t>=18*3600,1,'first'); T_motor_18h=T_motor_C(idx_18h); T_ar_motor_18h=T_ar_motor_C(idx_18h); T_parede_teto_18h=T_parede_teto_motor_C(idx_18h);
    fprintf(' -> 2d) Temp. Motor às 18h: %.2f °C\n', T_motor_18h); fprintf(' -> 2d) Temp. Ar (Motor) às 18h: %.2f °C\n', T_ar_motor_18h); fprintf(' -> 2d) Temp. Teto (Motor) às 18h: %.2f °C\n', T_parede_teto_18h);
    v_int_18h=p.m_dot_ar/(get_air_properties(Y(idx_18h,2)).rho*(2.5*2.5));
    h_motor_18h=calc_h_convec(p.D_motor,v_int_18h,Y(idx_18h,1),Y(idx_18h,2),'sphere',''); h_gerador_18h=calc_h_convec(p.D_gerador,v_int_18h,Y(idx_18h,8),Y(idx_18h,2),'sphere','');
    h_par_int_18h=calc_h_convec(2.5,v_int_18h,Y(idx_18h,10),Y(idx_18h,2),'plate','vertical'); h_par_ext_18h=calc_h_convec(2.5,0,Y(idx_18h,10),T_amb(t(idx_18h)),'plate','vertical');
    fprintf(' -> 2b) h_motor às 18h: %.2f W/m².°C\n', h_motor_18h); fprintf(' -> 2b) h_gerador às 18h: %.2f W/m².°C\n', h_gerador_18h);
    fprintf(' -> 2b) h_parede_interna às 18h: %.2f W/m².°C\n', h_par_int_18h); fprintf(' -> 2b) h_parede_externa às 18h: %.2f W/m².°C\n', h_par_ext_18h);
    R_vent=1/(p.m_dot_ar*p.cp_ar); R_parede_leste=1/(h_par_int_18h*p.A_parede_leste_motor)+1/(h_par_ext_18h*p.A_parede_leste_motor);
    R_walls_equiv=R_parede_leste/5; R_total_equiv=1/(1/R_vent+1/R_walls_equiv); fprintf(' -> 2c) R_ar_int_amb às 18h: %.4f °C/W\n', R_total_equiv);
    T_final_motor=max(T_motor_C); T_63_percent=T_inicial_C+0.632*(T_final_motor-T_inicial_C);
    idx_tau=find(T_motor_C>=T_63_percent,1,'first'); tau_motor_s=t(idx_tau)-t0; fprintf(' -> 2e) Constante de tempo do motor (tau): %.2f min\n', tau_motor_s/60);
elseif 0 %p.withFanFail
    fprintf('MODO ATIVO: Questão 3b - Falha da Ventoinha\n'); [max_T_motor,~]=max(T_motor_C); fprintf(' -> 3b) Temp. Máxima do Motor: %.2f °C\n', max_T_motor);
elseif p.withExhaustorFail
     fprintf('MODO ATIVO: Questão 3d - Falha do Exaustor\n'); [max_T_ar_res,~]=max(Y(:,6)-273.15); fprintf(' -> 3d) Temp. Máxima do Ar no Reservatório: %.2f °C\n', max_T_ar_res);
elseif p.withOnOffControl
    fprintf('MODO ATIVO: Questão 4 - Controle On-Off\n');
    T_on=100; T_off=80; rad_state=zeros(size(t)); current_state=false;
    for i=1:length(t), if Tsensor_motor_C(i)>=T_on, current_state=true; end; if Tsensor_motor_C(i)<=T_off, current_state=false; end; rad_state(i)=current_state; end
    on_events_idx=find(diff(rad_state)>0)+1;
    if length(on_events_idx)>9, intervalo_s=t(on_events_idx(10))-t(on_events_idx(9)); T_ar_cycle=T_ar_motor_C(on_events_idx(9):on_events_idx(10)); delta_T_ar=max(T_ar_cycle)-min(T_ar_cycle); fprintf(' -> 4b) Intervalo do ciclo: %.2f s\n', intervalo_s); fprintf(' -> 4c) Variação de Temp. do Ar no ciclo: %.2f °C\n', delta_T_ar);
    else, fprintf(' -> Ciclos insuficientes para análise da Questão 4.\n'); end; fprintf(' -> 4d) Para obter o novo intervalo, altere tau_sensor_motor em parametros.m e rode novamente.\n');
elseif p.withVariablePower
    fprintf('MODO ATIVO: Questão 5 - Potência Variável\n');
    [max_T_motor,~]=max(T_motor_C); [max_T_ar_motor,~]=max(T_ar_motor_C); fprintf(' -> 5b) Temp. Máxima do Motor: %.2f °C\n', max_T_motor); fprintf(' -> 5b) Temp. Máxima do Ar (Motor): %.2f °C\n', max_T_ar_motor);
    Pel_vec=arrayfun(@power_profile,t); idx_operacao=find(Pel_vec>0);
    Energia_eletrica_J=trapz(t(idx_operacao), Pel_vec(idx_operacao)); eta_motor=0.3; eta_gerador=0.9;
    P_comb_operacao=Pel_vec(idx_operacao)./(eta_motor*eta_gerador); Energia_comb_J=trapz(t(idx_operacao), P_comb_operacao);
    massa_comb_kg=(Energia_comb_J/1000)/p.poder_calorifico_diesel; volume_L=(massa_comb_kg/p.densidade_diesel)*1000;
    fprintf(' -> 5c) Consumo de Combustível: %.2f Litros\n', volume_L); fprintf(' -> 5c) Energia Elétrica Gerada: %.2f kWh\n', Energia_eletrica_J/(3.6e6));
end
fprintf('====================================================\n');

