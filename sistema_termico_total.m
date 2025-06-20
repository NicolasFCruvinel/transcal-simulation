% === sistema_termico_total_corrigido.m ===
function dYdt = sistema_termico_total(t, Y)
    p = parametros();

    % Estados térmicos (todos em Kelvin)
    Tmotor = Y(1);
    Tar_motor = Y(2);
    Tsensor_motor = Y(5);
    Tar_res = Y(6);
    Tsensor_res = Y(7);
    Tgerador = Y(8);
    Tbateria = Y(9);
    Tparede_leste_motor = Y(10);
    Tparede_oeste_motor = Y(11);
    Tparede_sul_motor = Y(12);
    Tparede_teto_motor = Y(13);
    Tparede_motor_int = Y(14);
    Tparede_res_ext = Y(15);

    % Ambiente
    Tamb = T_amb(t);
    T_cel = 0 + 273.15;  % Temperatura do céu em Kelvin

    % Cálculo dos coeficientes convectivos
    h_motor = calc_h_convec(p.D_motor, 3);       % Convecção forçada interna
    h_ext = calc_h_convec(2.5, 0.5);             % Convecção natural externa
    h_gerador = calc_h_convec(p.D_gerador, 3);
    h_bateria = calc_h_convec(p.D_bateria, 3);

    % Balanço de energia CORRIGIDO - considerando eficiências
    if p.withVariablePower
        Pel = power_profile(t);
    else
        Pel = 50e3; % 50 kW em W
    end

    % Eficiências conforme enunciado
    eta_gerador = 0.9;    % 90% eficiência do gerador
    eta_motor = 0.3;      % 30% eficiência do motor

    % Calor total do combustível (corrigido)
    Q_comb = (Pel / eta_gerador) / eta_motor;

    % Calor que efetivamente aquece o motor (40% conforme enunciado)
    Q_motor = 0.4 * Q_comb;

    % Radiador com controle on-off (item 4)
    if p.withOnOffControl
        T_set = 90 + 273.15;
        T_on = T_set + 10;
        T_off = T_set - 10;

        persistent isOn;
        if isempty(isOn), isOn = true; end

        if Tsensor_motor > T_on
            isOn = true;
        elseif Tsensor_motor < T_off
            isOn = false;
        end
        UA_rad = 2000 * isOn;
    elseif p.withFanFail && t >= 12 * 3600
        UA_rad = 100; % Item 3 - falha da ventoinha
    else
        UA_rad = 1000; % Valor padrão
    end

    % ========= TROCAS TÉRMICAS NO MOTOR =========
    Q_rad = UA_rad * (Tmotor - Tar_motor); % Calor do radiador

    % Convecção do motor com o ar interno
    Q_conv_motor = h_motor * p.A_motor * (Tmotor - Tar_motor);

    % Radiação do motor para as paredes internas
    Q_rad_motor = p.sigma * p.epsilon * p.A_motor * (Tmotor^4 - Tparede_motor_int^4);

    % Renovação de ar no espaço do motor
    Q_ar_motor = p.m_dot_ar * p.cp_ar * (Tamb - Tar_motor);

    % Convecção do ar interno com as paredes
    Q_conv_ar_parede = h_motor * p.A_parede_motor * (Tar_motor - Tparede_motor_int);

    % Condução através da parede divisória (lã de rocha)
    Q_cond_larocha = p.k_larocha * p.A_div / p.esp_larocha * (Tparede_motor_int - Tparede_res_ext);

    % Convecção no lado do reservatório
    Q_conv_res_parede = h_motor * p.A_parede_res * (Tar_res - Tparede_res_ext);

    % Perda para o solo (usando fator de forma)
    Q_solo_motor = p.k_solo * p.A_base_motor / p.S_motor * (Tmotor - p.Tinf);
    Q_solo_res = p.k_solo * p.A_base_res / p.S_res * (Tar_res - p.Tinf);

    % ========= PAREDES LATERAIS =========
    % Convecção interna
    Q_leste_conv = h_motor * p.A_parede_leste_motor * (Tar_motor - Tparede_leste_motor);
    Q_oeste_conv = h_motor * p.A_parede_oeste_motor * (Tar_motor - Tparede_oeste_motor);
    Q_sul_conv = h_motor * p.A_parede_sul_motor * (Tar_motor - Tparede_sul_motor);
    Q_teto_conv = h_motor * p.A_parede_teto_motor * (Tar_motor - Tparede_teto_motor);

    % Convecção externa
    Q_leste_ext = h_ext * p.A_parede_leste_motor * (Tparede_leste_motor - Tamb);
    Q_oeste_ext = h_ext * p.A_parede_oeste_motor * (Tparede_oeste_motor - Tamb);
    Q_sul_ext = h_ext * p.A_parede_sul_motor * (Tparede_sul_motor - Tamb);
    Q_teto_ext = h_ext * p.A_parede_teto_motor * (Tparede_teto_motor - Tamb);

    % Radiação para o céu
    Q_leste_rad = p.sigma * p.epsilon * p.A_parede_leste_motor * (Tparede_leste_motor^4 - T_cel^4);
    Q_oeste_rad = p.sigma * p.epsilon * p.A_parede_oeste_motor * (Tparede_oeste_motor^4 - T_cel^4);
    Q_sul_rad = p.sigma * p.epsilon * p.A_parede_sul_motor * (Tparede_sul_motor^4 - T_cel^4);
    Q_teto_rad = p.sigma * p.epsilon * p.A_parede_teto_motor * (Tparede_teto_motor^4 - T_cel^4);

    % ========= EQUAÇÕES DIFERENCIAIS =========
    % Motor (corrigido - balanço energético preciso)
    dTmotor = (Q_motor - Q_rad - Q_conv_motor - Q_rad_motor - Q_solo_motor) / (p.m_motor * p.cp_motor);

    % Ar no espaço do motor
    dTar_motor = (Q_rad + Q_conv_motor + Q_rad_motor + Q_ar_motor - ...
                 Q_conv_ar_parede - Q_leste_conv - Q_oeste_conv - Q_sul_conv - Q_teto_conv) / ...
                 (p.m_ar * p.cp_ar);

    % Ar no reservatório
    dTar_res = (Q_cond_larocha + Q_conv_res_parede - Q_solo_res) / (p.m_ar_res * p.cp_ar_res);

    % Sensores (1ª ordem)
    dTsensor_motor = (Tmotor - Tsensor_motor) / p.tau_sensor_motor;
    dTsensor_res = (Tar_res - Tsensor_res) / p.tau_sensor_res;

    % Gerador (considerando 5% do calor total)
    dTgerador = (0.05 * Q_comb - h_gerador * p.A_gerador * (Tgerador - Tar_motor)) / ...
                (p.m_gerador * p.cp_gerador);

    % Bateria (considerando 1% do calor total)
    dTbateria = (0.01 * Q_comb - h_bateria * p.A_bateria * (Tbateria - Tar_motor)) / ...
                (p.m_bateria * p.cp_bateria);

    % Paredes laterais
    dTleste = (Q_leste_conv - Q_leste_ext - Q_leste_rad) / (p.m_parede_leste_motor * p.cp_parede_leste_motor);
    dToeste = (Q_oeste_conv - Q_oeste_ext - Q_oeste_rad) / (p.m_parede_oeste_motor * p.cp_parede_oeste_motor);
    dTsul = (Q_sul_conv - Q_sul_ext - Q_sul_rad) / (p.m_parede_sul_motor * p.cp_parede_sul_motor);
    dTteto = (Q_teto_conv - Q_teto_ext - Q_teto_rad) / (p.m_parede_teto_motor * p.cp_parede_teto_motor);

    % Parede divisória
    dT_parede_motor_int = (Q_conv_ar_parede - Q_cond_larocha) / (p.m_parede_motor * p.cp_parede_motor);
    dT_parede_res_ext = (Q_cond_larocha - Q_conv_res_parede) / (p.m_parede_res * p.cp_parede_res);

    % ========= RETORNO DAS DERIVADAS =========
    dYdt = [dTmotor; dTar_motor; 0; 0; dTsensor_motor; dTar_res; dTsensor_res; ...
            dTgerador; dTbateria; dTleste; dToeste; dTsul; dTteto; ...
            dT_parede_motor_int; dT_parede_res_ext];

    % Verificação de sanidade (evitar overflow numérico)
    if any(isnan(dYdt)) || any(isinf(dYdt))
        error('Derivadas inválidas detectadas no tempo t=%.2f', t);
    end
end
