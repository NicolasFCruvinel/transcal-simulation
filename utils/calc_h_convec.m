function h = calc_h_convec(D, vel, DeltaT_surface_air, geometry, orientation)
    % Propriedades do ar (aproximadas para 300K)
    k_ar = 0.0263;   % Condutividade térmica [W/m.K]
    nu_ar = 1.589e-5;% Viscosidade cinemática [m²/s]
    Pr = 0.707;      % Número de Prandtl
    beta = 1/300;    % Coeficiente de expansão térmica [1/K]
    g = 9.81;        % Aceleração gravitacional [m/s²]

    if vel > 0.1 % --- CONVECÇÃO FORÇADA ---
        Re = vel * D / nu_ar;
        if strcmp(geometry, 'sphere')
            Nu = 2 + (0.4 * Re^0.5 + 0.06 * Re^(2/3)) * Pr^0.4;
        elseif strcmp(geometry, 'plate')
            Nu = 0.664 * Re^0.5 * Pr^(1/3); % Fluxo laminar
        else
            error('Geometria desconhecida para convecção forçada: %s', geometry);
        end

    else % --- CONVECÇÃO NATURAL ---
        DeltaT = max(1e-6, abs(DeltaT_surface_air));
        Ra = (g * beta * DeltaT * D^3 / nu_ar^2) * Pr;

        if strcmp(geometry, 'sphere')
            Nu = 2 + (0.589 * Ra^(1/4)) / (1 + (0.469 / Pr)^(9/16))^(4/9);

        elseif strcmp(geometry, 'plate')
            % --- Lógica Explícita para Orientação da Placa ---
            switch orientation
                case 'vertical'
                    % Correlação de Churchill e Chu para placa vertical
                    Nu = (0.825 + (0.387 * Ra^(1/6)) / (1 + (0.492 / Pr)^(9/16))^(8/27))^2;

                case 'horizontal_up'
                    if Ra > 1e7 && Ra < 1e11
                        Nu = 0.15 * Ra^(1/3); % Turbulento
                    else
                        Nu = 0.54 * Ra^(1/4); % Laminar
                    end

                case 'horizontal_down'
                    Nu = 0.27 * Ra^(1/4);

                otherwise
                    error('Orientação de placa desconhecida para convecção natural: %s', orientation);
            end
        else
            error('Geometria desconhecida para convecção natural: %s', geometry);
        end
    end

    % Calcula o coeficiente convectivo a partir do Nusselt
    h = Nu * k_ar / D;
end

