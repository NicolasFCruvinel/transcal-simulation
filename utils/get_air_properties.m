function props = get_air_properties(T_K)
    % === get_air_properties.m ===
    % Retorna as propriedades do ar atmosférico a uma dada temperatura em Kelvin.
    % Os dados são interpolados da Tabela A.4 do Incropera, "Fundamentals of
    % Heat and Mass Transfer".

    % Dados da Tabela A.4 (Ar Atmosférico)
    % T [K], rho [kg/m^3], cp [J/kg.K], mu*1e7 [N.s/m^2], nu*1e6 [m^2/s], k*1e3 [W/m.K], Pr
    table_data = [ ...
        100, 3.5562, 1032,  71.1,  2.00,   9.3, 0.768;
        150, 2.3675, 1012, 103.4,  4.37,  13.8, 0.744;
        200, 1.7740, 1007, 132.5,  7.47,  18.1, 0.730;
        250, 1.4184, 1006, 159.6, 11.25,  22.3, 0.720;
        300, 1.1614, 1007, 184.6, 15.89,  26.3, 0.707;
        350, 0.9950, 1009, 208.2, 20.92,  30.0, 0.700;
        400, 0.8711, 1014, 230.1, 26.41,  33.8, 0.690;
        450, 0.7740, 1021, 250.7, 32.39,  37.3, 0.686;
        500, 0.6964, 1030, 270.1, 38.79,  40.7, 0.684;
        550, 0.6329, 1039, 288.4, 45.57,  43.9, 0.683;
        600, 0.5804, 1051, 305.8, 52.69,  46.9, 0.685
    ];

    T_table = table_data(:,1);

    % Interpolação linear para cada propriedade
    props.rho = interp1(T_table, table_data(:,2), T_K, 'linear', 'extrap');
    props.cp  = interp1(T_table, table_data(:,3), T_K, 'linear', 'extrap');
    props.mu  = interp1(T_table, table_data(:,4), T_K, 'linear', 'extrap') * 1e-7;
    props.nu  = interp1(T_table, table_data(:,5), T_K, 'linear', 'extrap') * 1e-6;
    props.k   = interp1(T_table, table_data(:,6), T_K, 'linear', 'extrap') * 1e-3;
    props.pr  = interp1(T_table, table_data(:,7), T_K, 'linear', 'extrap');

    % Calcula as propriedades derivadas
    props.beta = 1 / T_K; % Para gases ideais
    props.alpha = props.k / (props.rho * props.cp); % Difusividade térmica
end
