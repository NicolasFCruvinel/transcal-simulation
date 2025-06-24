function dYdt = sistema_termico_total(t, Y, p, Tinit_K)
    % --- Desempacotamento do Vetor de Estados Y (19 estados) ---
    Tmotor = Y(1); Tar_motor = Y(2); Treservatorio = Y(3); m_res_atual = Y(4);
    Tsensor_motor = Y(5); Tar_res = Y(6); Tsensor_res = Y(7); Tgerador = Y(8);
    Tbateria = Y(9); Tparede_leste_motor = Y(10); Tparede_oeste_motor = Y(11);
    Tparede_sul_motor = Y(12); Tparede_teto_motor = Y(13); Tparede_motor_int = Y(14);
    Tparede_res_ext = Y(15); Tparede_norte_res = Y(16); Tparede_leste_res = Y(17);
    Tparede_oeste_res = Y(18); Tparede_teto_res = Y(19);

    Tamb = T_amb(t); Tceu = 0 + 273.15;

    % --- FONTES DE CALOR E PARÂMETROS DINÂMICOS ---
    if p.withVariablePower, Pel = power_profile(t); else, Pel = 50e3; end
    if Pel > 0 && m_res_atual > 1, eta_gerador = 0.9; eta_motor = 0.3; Q_comb_total = (Pel/eta_gerador)/eta_motor; Q_gen_motor = 0.4*Q_comb_total; Q_gen_gerador = (Pel/eta_gerador-Pel); m_dot_combustivel = (Q_comb_total/1000)/p.poder_calorifico_diesel; else, Q_gen_motor = 0; Q_gen_gerador = 0; m_dot_combustivel = 0; end
    Q_gen_bateria = 0; G = radiacao_solar(t, p);
    if p.withOnOffControl, persistent isRadOn; if isempty(isRadOn), isRadOn = false; end; T_on_K = 373.15; T_off_K = 353.15; if Tsensor_motor >= T_on_K, isRadOn = true; elseif Tsensor_motor <= T_off_K, isRadOn = false; end; if isRadOn, UA_rad = 2000; else, UA_rad = 0; end; elseif p.withFanFail && t >= 12*3600, UA_rad = 100; else, UA_rad = 1000; end
    m_dot_ar_res_atual = p.m_dot_ar_res; if p.withExhaustorFail, m_dot_ar_res_atual = 2e-3; end

    % --- CÁLCULO DAS TROCAS DE CALOR ---
    h_int = calc_h_convec(p.D_motor, 3, 0);

    % Lado Motor
    Q_radiador = UA_rad * (Tmotor - Tar_motor);
    Q_conv_motor_ar = h_int * p.A_motor * (Tmotor - Tar_motor);
    Q_vent_motor = p.m_dot_ar * p.cp_ar * (Tamb - Tar_motor);
    A_total_int = p.A_parede_leste_motor + p.A_parede_oeste_motor + p.A_parede_sul_motor + p.A_parede_teto_motor + p.A_parede_motor;
    T_sup_media_K4 = (p.A_parede_leste_motor*Tparede_leste_motor^4+p.A_parede_oeste_motor*Tparede_oeste_motor^4+p.A_parede_sul_motor*Tparede_sul_motor^4+p.A_parede_teto_motor*Tparede_teto_motor^4+p.A_parede_motor*Tparede_motor_int^4)/A_total_int;
    Q_rad_total_motor = p.sigma*p.epsilon*p.A_motor*(Tmotor^4 - T_sup_media_K4);
    Q_rad_para_leste_mot = Q_rad_total_motor*(p.A_parede_leste_motor/A_total_int); Q_rad_para_oeste_mot = Q_rad_total_motor*(p.A_parede_oeste_motor/A_total_int);
    Q_rad_para_sul_mot = Q_rad_total_motor*(p.A_parede_sul_motor/A_total_int); Q_rad_para_teto_mot = Q_rad_total_motor*(p.A_parede_teto_motor/A_total_int);
    Q_rad_para_divisoria = Q_rad_total_motor*(p.A_parede_motor/A_total_int);

    % Lado Reservatório
    Q_cond_div = (p.A_div/(p.esp_larocha/p.k_larocha))*(Tparede_motor_int - Tparede_res_ext);
    Q_conv_res_ar = h_int*p.A_res*(Treservatorio - Tar_res);
    Q_solo_res = p.k_solo*p.S_res*(Treservatorio - p.Tinf);
    Q_saida_combustivel = m_dot_combustivel*p.cp_res*(Treservatorio - Tinit_K);
    Q_vent_res = m_dot_ar_res_atual*p.cp_ar_res*(Tamb - Tar_res);
    Q_conv_parede_div_res_ar = h_int*p.A_parede_res*(Tparede_res_ext - Tar_res);

    % Paredes Externas (Lado Motor)
    h_ext = calc_h_convec(2.5,0,Tparede_teto_motor-Tamb); Q_conv_in_teto = h_int*p.A_parede_teto_motor*(Tar_motor-Tparede_teto_motor); Q_conv_out_teto=h_ext*p.A_parede_teto_motor*(Tparede_teto_motor-Tamb); Q_rad_out_teto=p.sigma*p.epsilon*p.A_parede_teto_motor*(Tparede_teto_motor^4-Tceu^4); Q_solar_teto=p.alpha*p.A_parede_teto_motor*G.teto;
    h_ext = calc_h_convec(2.5,0,Tparede_leste_motor-Tamb); Q_conv_in_leste=h_int*p.A_parede_leste_motor*(Tar_motor-Tparede_leste_motor); Q_conv_out_leste=h_ext*p.A_parede_leste_motor*(Tparede_leste_motor-Tamb); Q_rad_out_leste=p.sigma*p.epsilon*p.A_parede_leste_motor*(Tparede_leste_motor^4-Tceu^4); Q_solar_leste=p.alpha*p.A_parede_leste_motor*G.leste;
    h_ext = calc_h_convec(2.5,0,Tparede_oeste_motor-Tamb); Q_conv_in_oeste=h_int*p.A_parede_oeste_motor*(Tar_motor-Tparede_oeste_motor); Q_conv_out_oeste=h_ext*p.A_parede_oeste_motor*(Tparede_oeste_motor-Tamb); Q_rad_out_oeste=p.sigma*p.epsilon*p.A_parede_oeste_motor*(Tparede_oeste_motor^4-Tceu^4); Q_solar_oeste=p.alpha*p.A_parede_oeste_motor*G.oeste;
    h_ext = calc_h_convec(2.5,0,Tparede_sul_motor-Tamb); Q_conv_in_sul=h_int*p.A_parede_sul_motor*(Tar_motor-Tparede_sul_motor); Q_conv_out_sul=h_ext*p.A_parede_sul_motor*(Tparede_sul_motor-Tamb); Q_rad_out_sul=p.sigma*p.epsilon*p.A_parede_sul_motor*(Tparede_sul_motor^4-Tceu^4); Q_solar_sul=p.alpha*p.A_parede_sul_motor*G.sul;

    % Paredes Externas (Lado Reservatório) - NOVOS TERMOS
    h_ext = calc_h_convec(2.5,0,Tparede_norte_res-Tamb); Q_conv_in_norte_res=h_int*p.A_parede_norte_res*(Tar_res-Tparede_norte_res); Q_conv_out_norte_res=h_ext*p.A_parede_norte_res*(Tparede_norte_res-Tamb); Q_rad_out_norte_res=p.sigma*p.epsilon*p.A_parede_norte_res*(Tparede_norte_res^4-Tceu^4); Q_solar_norte_res=p.alpha*p.A_parede_norte_res*G.norte;
    h_ext = calc_h_convec(2.5,0,Tparede_leste_res-Tamb); Q_conv_in_leste_res=h_int*p.A_parede_leste_res*(Tar_res-Tparede_leste_res); Q_conv_out_leste_res=h_ext*p.A_parede_leste_res*(Tparede_leste_res-Tamb); Q_rad_out_leste_res=p.sigma*p.epsilon*p.A_parede_leste_res*(Tparede_leste_res^4-Tceu^4); Q_solar_leste_res=p.alpha*p.A_parede_leste_res*G.leste;
    h_ext = calc_h_convec(2.5,0,Tparede_oeste_res-Tamb); Q_conv_in_oeste_res=h_int*p.A_parede_oeste_res*(Tar_res-Tparede_oeste_res); Q_conv_out_oeste_res=h_ext*p.A_parede_oeste_res*(Tparede_oeste_res-Tamb); Q_rad_out_oeste_res=p.sigma*p.epsilon*p.A_parede_oeste_res*(Tparede_oeste_res^4-Tceu^4); Q_solar_oeste_res=p.alpha*p.A_parede_oeste_res*G.oeste;
    h_ext = calc_h_convec(2.5,0,Tparede_teto_res-Tamb); Q_conv_in_teto_res=h_int*p.A_parede_teto_res*(Tar_res-Tparede_teto_res); Q_conv_out_teto_res=h_ext*p.A_parede_teto_res*(Tparede_teto_res-Tamb); Q_rad_out_teto_res=p.sigma*p.epsilon*p.A_parede_teto_res*(Tparede_teto_res^4-Tceu^4); Q_solar_teto_res=p.alpha*p.A_parede_teto_res*G.teto;

    % Outros
    R_conv_chao=1/(h_int*p.A_base_motor); R_cond_chao=1/(p.S_motor*p.k_solo); Q_chao_motor=(Tar_motor-p.Tinf)/(R_conv_chao+R_cond_chao);
    Q_conv_gerador_ar=h_int*p.A_gerador*(Tgerador-Tar_motor); Q_conv_bateria_ar=h_int*p.A_bateria*(Tbateria-Tar_motor);
    Q_conv_ar_parede_div_motor=h_int*p.A_parede_motor*(Tar_motor-Tparede_motor_int);

    % --- EQUAÇÕES DIFERENCIAIS ---
    dm_res_dt = -m_dot_combustivel;
    dTreservatorio_dt = (-Q_conv_res_ar - Q_solo_res - Q_saida_combustivel) / (m_res_atual * p.cp_res);
    dT_ar_res = (Q_conv_parede_div_res_ar + Q_conv_res_ar + Q_vent_res - Q_conv_in_norte_res - Q_conv_in_leste_res - Q_conv_in_oeste_res - Q_conv_in_teto_res) / (p.m_ar_res * p.cp_ar_res);
    dTmotor = (Q_gen_motor - Q_radiador - Q_conv_motor_ar - Q_rad_total_motor) / (p.m_motor * p.cp_motor);
    dT_ar_motor = (Q_conv_motor_ar + Q_conv_gerador_ar + Q_conv_bateria_ar + Q_vent_motor - Q_conv_ar_parede_div_motor - Q_conv_in_teto - Q_conv_in_leste - Q_conv_in_oeste - Q_conv_in_sul - Q_chao_motor) / (p.m_ar * p.cp_ar);
    dT_parede_motor_int = (Q_rad_para_divisoria + Q_conv_ar_parede_div_motor - Q_cond_div) / (p.m_parede_motor * p.cp_parede_motor);
    dT_parede_res_ext = (Q_cond_div - Q_conv_parede_div_res_ar) / (p.m_parede_res * p.cp_parede_res);
    dT_parede_teto_motor = (Q_rad_para_teto_mot + Q_conv_in_teto - Q_conv_out_teto - Q_rad_out_teto + Q_solar_teto) / (p.m_parede_teto_motor * p.cp_parede_teto_motor);
    dT_parede_leste_motor = (Q_rad_para_leste_mot + Q_conv_in_leste - Q_conv_out_leste - Q_rad_out_leste + Q_solar_leste) / (p.m_parede_leste_motor * p.cp_parede_leste_motor);
    dT_parede_oeste_motor = (Q_rad_para_oeste_mot + Q_conv_in_oeste - Q_conv_out_oeste - Q_rad_out_oeste + Q_solar_oeste) / (p.m_parede_oeste_motor * p.cp_parede_oeste_motor);
    dT_parede_sul_motor = (Q_rad_para_sul_mot + Q_conv_in_sul - Q_conv_out_sul - Q_rad_out_sul + Q_solar_sul) / (p.m_parede_sul_motor * p.cp_parede_sul_motor);
    % NOVAS EQUAÇÕES PARA AS PAREDES DO RESERVATÓRIO
    dT_parede_norte_res_dt = (Q_conv_in_norte_res - Q_conv_out_norte_res - Q_rad_out_norte_res + Q_solar_norte_res) / (p.m_parede_norte_res * p.cp_parede_norte_res);
    dT_parede_leste_res_dt = (Q_conv_in_leste_res - Q_conv_out_leste_res - Q_rad_out_leste_res + Q_solar_leste_res) / (p.m_parede_leste_res * p.cp_parede_leste_res);
    dT_parede_oeste_res_dt = (Q_conv_in_oeste_res - Q_conv_out_oeste_res - Q_rad_out_oeste_res + Q_solar_oeste_res) / (p.m_parede_oeste_res * p.cp_parede_oeste_res);
    dT_parede_teto_res_dt = (Q_conv_in_teto_res - Q_conv_out_teto_res - Q_rad_out_teto_res + Q_solar_teto_res) / (p.m_parede_teto_res * p.cp_parede_teto_res);

    dTgerador = (Q_gen_gerador - Q_conv_gerador_ar) / (p.m_gerador * p.cp_gerador);
    dTbateria = (Q_gen_bateria - Q_conv_bateria_ar) / (p.m_bateria * p.cp_bateria);
    dTsensor_motor = (Tmotor - Tsensor_motor) / p.tau_sensor_motor;
    dTsensor_res = (Tar_res - Tsensor_res) / p.tau_sensor_res;

    % --- MONTAGEM DO VETOR DE DERIVADAS dYdt ---
    dYdt = zeros(19, 1);
    dYdt([1:19]) = [dTmotor; dT_ar_motor; dTreservatorio_dt; dm_res_dt; dTsensor_motor; dT_ar_res; dTsensor_res; dTgerador; dTbateria; dT_parede_leste_motor; dT_parede_oeste_motor; dT_parede_sul_motor; dT_parede_teto_motor; dT_parede_motor_int; dT_parede_res_ext; dT_parede_norte_res_dt; dT_parede_leste_res_dt; dT_parede_oeste_res_dt; dT_parede_teto_res_dt];
end

