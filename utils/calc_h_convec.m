function h = calc_h_convec(D, vel)
    % Calcula coeficiente de transferência de calor convectivo
    % Inputs:
    %   D - diâmetro característico [m]
    %   vel - velocidade do fluido [m/s]
    % Output:
    %   h - coeficiente convectivo [W/m².K]

    k_ar = 0.026;    % Condutividade térmica do ar [W/m.K]
    nu_ar = 1.5e-5;  % Viscosidade cinemática do ar [m²/s]
    Pr = 0.7;        % Número de Prandtl

    if vel > 0.1 % Convecção forçada
        Re = vel * D / nu_ar;
        Nu = 0.3 + (0.62 * Re^0.5 * Pr^(1/3)) / (1 + (0.4/Pr)^(2/3))^0.25 * ...
             (1 + (Re/282000)^(5/8))^(4/5);
    else % Convecção natural
        beta = 1/300; % Coeficiente de expansão térmica [1/K]
        g = 9.81;     % Aceleração gravitacional [m/s²]
        DeltaT = 10;   % Diferença de temperatura estimada [K]

        Gr = g * beta * DeltaT * D^3 / nu_ar^2;
        Nu = 2 + 0.43 * (Gr * Pr)^0.25;
    end

    h = Nu * k_ar / D;
end

% TODO: avaliar dinamicamente valor convectivo calculado
