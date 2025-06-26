function h = calc_h_convec(D, vel, Ts, T_fluid, geometry, orientation)
    % === calc_h_convec.m (v8 - Lógica Defensiva para Solver de EDO) ===
    % Versão final com lógica robusta que evita erros fatais dentro do
    % solver de EDOs, usando um caso padrão para orientações inesperadas.

    % Propriedades do ar (aproximadas para 300K)
    k_ar = 0.0263;   % Condutividade térmica [W/m.K]
    nu_ar = 1.589e-5;% Viscosidade cinemática [m²/s]
    Pr = 0.707;      % Número de Prandtl
    beta = 1/300;    % Coeficiente de expansão térmica [1/K]
    g = 9.81;        % Aceleração gravitacional [m/s²]

    if vel > 0.1 % --- CONVECÇÃO FORÇADA ---
        % Para convecção forçada, usamos a temperatura do fluido (T_fluid)
        props = get_air_properties(T_fluid);
        props_s = get_air_properties(Ts);
        mu_s = props_s.mu;

        Re = vel * D / props.nu;

        if strcmp(geometry, 'sphere')
            Nu = 2 + (0.4 * Re^0.5 + 0.06 * Re^(2/3)) * props.pr^0.4 * (props.mu / mu_s)^0.25;
        elseif strcmp(geometry, 'plate')
            Nu = 0.664 * Re^0.5 * props.pr^(1/3); % Fluxo laminar
        else
            Nu = 0; % Geometria desconhecida
        end

    else % --- CONVECÇÃO NATURAL ---
        % Para convecção natural, usamos a temperatura de filme
        T_film = (Ts + T_fluid) / 2;
        props = get_air_properties(T_film);

        DeltaT = abs(Ts - T_fluid);
        if DeltaT < 1e-6, h = 0; return; end

        Ra = (g * props.beta * DeltaT * D^3) / (props.nu * props.alpha);

        if strcmp(geometry, 'sphere')
            Nu = 2 + (0.589 * Ra^(1/4)) / (1 + (0.469 / props.pr)^(9/16))^(4/9);

        elseif strcmp(geometry, 'plate')
            % CORREÇÃO: Lógica com if/elseif/else para ser mais robusta
            if strcmp(orientation, 'horizontal_up')
                if Ra > 1e7 && Ra < 1e11, Nu = 0.15 * Ra^(1/3); else, Nu = 0.54 * Ra^(1/4); end
            elseif strcmp(orientation, 'horizontal_down')
                Nu = 0.27 * Ra^(1/4);
            else % Assume 'vertical' como padrão para qualquer outro caso
                Nu = (0.825 + (0.387 * Ra^(1/6)) / (1 + (0.492 / props.pr)^(9/16))^(8/27))^2;
            end
        else
            Nu = 0; % Geometria desconhecida
        end
    end

    % Calcula o coeficiente convectivo a partir do Nusselt
    h = props.k * Nu / D;

    % Garante que h não é NaN ou Inf para não parar o solver
    if isnan(h) || isinf(h)
        h = 0;
    end
end

