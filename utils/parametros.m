function p = parametros()
    % === parametros.m ===
    % Ficheiro centralizado com todos os parâmetros físicos do projeto.

    % --- FLAGS DE CONTROLE PARA CADA QUESTÃO ---
    p.withFanFail = false;
    p.withExhaustorFail = false;
    p.withOnOffControl = true;
    p.withVariablePower = false;

    % --- CONSTANTES FÍSICAS E DE SUPERFÍCIE ---
    p.sigma = 5.67e-8; p.k_solo = 1; p.Tinf = 23 + 273.15;
    p.g = 9.81; p.epsilon = 0.9; p.alpha = 0.7;

    % --- PARÂMETROS DO COMBUSTÍVEL (DIESEL) ---
    p.poder_calorifico_diesel = 43000; % [kJ/kg]
    p.densidade_diesel = 850;          % [kg/m³]

    % --- PARÂMETROS DE RADIAÇÃO SOLAR (MODELO ASHRAE) ---
    p.albedo_solo = 0.1; p.rad_A = 1130; p.rad_B = 0.174; p.rad_C = 0.136;
    p.solar_noon_hour = 13;

    % --- GEOMETRIA, MASSA E PROPRIEDADES TÉRMICAS ---
    % LADO MOTOR
    p.m_motor = 400; p.cp_motor = 600; p.A_motor = 2.0; p.D_motor = 0.8;
    p.m_gerador = 100; p.cp_gerador = 500; p.D_gerador = 0.5; p.A_gerador = 0.8;
    p.m_bateria = 40; p.cp_bateria = 800; p.D_bateria = 0.3; p.A_bateria = 0.3;
    p.m_ar = 17; p.cp_ar = 1000; p.m_dot_ar = 2;
    p.A_parede_leste_motor = 6.25; p.m_parede_leste_motor = 100; p.cp_parede_leste_motor = 460;
    p.A_parede_oeste_motor = 6.25; p.m_parede_oeste_motor = 100; p.cp_parede_oeste_motor = 460;
    p.A_parede_sul_motor = 6.25; p.m_parede_sul_motor = 100; p.cp_parede_sul_motor = 460;
    p.A_parede_teto_motor = 6.25; p.m_parede_teto_motor = 100; p.cp_parede_teto_motor = 460;
    p.A_base_motor = 6.25; p.m_chao_motor = 100; p.cp_chao_motor = 460; % Chão do motor

    % PAREDE DIVISÓRIA
    p.m_parede_motor = 100; p.cp_parede_motor = 460; p.A_parede_motor = 6.25;
    p.k_larocha = 0.03; p.esp_larocha = 0.1; p.A_div = 6.25;

    % LADO RESERVATÓRIO
    p.m_res = 7200; p.cp_res = 1800; p.A_res = 24;
    p.m_ar_res = 23; p.cp_ar_res = 1000; p.m_dot_ar_res = 2;
    p.m_parede_res = 100; p.cp_parede_res = 460; p.A_parede_res = 6.25;
    p.A_parede_norte_res = 6.25; p.m_parede_norte_res = 100; p.cp_parede_norte_res = 460;
    p.A_parede_leste_res = 8.5;  p.m_parede_leste_res = 130; p.cp_parede_leste_res = 460;
    p.A_parede_oeste_res = 8.5;  p.m_parede_oeste_res = 130; p.cp_parede_oeste_res = 460;
    p.A_parede_teto_res = 8.5;   p.m_parede_teto_res = 130;  p.cp_parede_teto_res = 460;
    p.A_base_res = 8.5; p.m_chao_reserv = 130; p.cp_chao_reserv = 460; % Chão do reservatório

    % SENSORES E SOLO
    p.tau_sensor_motor = 30; p.tau_sensor_res = 300;
    p.S_motor = 5.84541;
    p.S_res = 6.81107;
end

