% === parametros_corrigidos.m ===
function p = parametros()
    % Constantes físicas
    p.sigma = 5.67e-8;      % Constante de Stefan-Boltzmann [W/m²K⁴]
    p.k_solo = 1;           % Condutividade térmica do solo [W/m.K]
    p.Tinf = 23 + 273.15;   % Temperatura do solo profundo [K]
    p.g = 9.81;             % Aceleração da gravidade [m/s²]

    % Propriedades de superfície
    p.epsilon = 0.9;        % Emissividade
    p.alpha = 0.7;          % Absortividade solar

    % ===== MOTOR =====
    p.m_motor = 400;        % Massa [kg]
    p.cp_motor = 600;       % Calor específico [J/kg.K]
    p.A_motor = 2.0;        % Área superficial [m²]
    p.D_motor = 0.8;        % Diâmetro característico [m]

    % ===== GERADOR =====
    p.m_gerador = 100;      % Massa [kg]
    p.cp_gerador = 500;     % Calor específico [J/kg.K]
    p.D_gerador = 0.5;      % Diâmetro [m]
    p.A_gerador = 0.8;      % Área [m²]

    % ===== BATERIA =====
    p.m_bateria = 40;       % Massa [kg]
    p.cp_bateria = 800;     % Calor específico [J/kg.K]
    p.D_bateria = 0.3;      % Diâmetro [m]
    p.A_bateria = 0.3;      % Área [m²]

    % ===== AR NO ESPAÇO DO MOTOR =====
    p.m_ar = 17;            % Massa de ar [kg]
    p.cp_ar = 1000;         % Calor específico [J/kg.K]
    p.m_dot_ar = 20;        % Vazão mássica [kg/s]

    % ===== PAREDES =====
    % Paredes laterais do motor
    p.A_parede_leste_motor = 6.25;  % Área [m²]
    p.m_parede_leste_motor = 100;   % Massa [kg]
    p.cp_parede_leste_motor = 460;  % Calor específico [J/kg.K]

    p.A_parede_oeste_motor = 6.25;
    p.m_parede_oeste_motor = 100;
    p.cp_parede_oeste_motor = 460;

    p.A_parede_sul_motor = 6.25;
    p.m_parede_sul_motor = 100;
    p.cp_parede_sul_motor = 460;

    p.A_parede_teto_motor = 6.25;
    p.m_parede_teto_motor = 100;
    p.cp_parede_teto_motor = 460;

    % Parede divisória (lado do motor)
    p.m_parede_motor = 100;
    p.cp_parede_motor = 460;
    p.A_parede_motor = 6.25;

    % Lã de rocha (isolamento)
    p.k_larocha = 0.03;     % Condutividade [W/m.K]
    p.esp_larocha = 0.1;    % Espessura [m]
    p.A_div = 6.25;         % Área [m²]

    % ===== RESERVATÓRIO =====
    p.m_res = 7200;         % Massa do reservatório + diesel [kg]
    p.cp_res = 1800;        % Calor específico [J/kg.K]
    p.A_res = 24;           % Área [m²]

    % Parede divisória (lado do motor)
    p.m_parede_res = 100;
    p.cp_parede_res = 460;
    p.A_parede_res = 6.25;

    % Ar no espaço do reservatório
    p.m_ar_res = 23;        % Massa de ar [kg]
    p.cp_ar_res = 1000;     % Calor específico [J/kg.K]
    p.m_dot_ar_res = 20;    % Vazão mássica [kg/s]

    % ===== SENSORES =====
    p.tau_sensor_motor = 10;        % Constante de tempo [s]
    p.tau_sensor_res = 5 * 60;      % Constante de tempo [s]

    % ===== FATORES DE FORMA (obtidos via EF) =====
    p.S_motor = 6.81107;            % Fator de forma base motor [m]
    p.A_base_motor = 2.5 * 2.5;     % Área base motor [m²]
    p.S_res = 5.84541;              % Fator de forma base reservatório [m]
    p.A_base_res = 2.5 * 3.4;       % Área base reservatório [m²]

    % ===== FLAGS DE CONTROLE =====
    p.withFanFail = false;          % Simular falha da ventoinha (item 3)
    p.withExhaustorFail = false;    % Simular falha do exaustor (item 3d)
    p.withVariablePower = false;    % Usar perfil de potência variável (item 5)
    p.withOnOffControl = false;     % Usar controle on-off (item 4)
end
