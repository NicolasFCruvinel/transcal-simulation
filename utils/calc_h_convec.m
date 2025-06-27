function h = calc_h_convec(D, vel, Ts, T_fluid, geometry, orientation)
    % --- Função Interna para Calcular Propriedades do Ar ---
    function props = get_air_props_poly(T)
        % Fórmulas de aproximação polinomial para propriedades do ar
        props.k = 2.414e-2 .* (T./273.15).^0.9;
        props.nu = 1.326e-5 .* (T./273.15).^1.7;
        props.mu = 1.716e-5 .* (T./273.15).^1.7;
        props.pr = 0.715 - 2.5e-4 .* (T - 273.15);
        props.beta = 1 ./ T;
        props.rho = 1.293 .* (273.15 ./ T);
        props.cp = 1007;
        props.alpha = props.k ./ (props.rho .* props.cp);
    end

    % --- Lógica Principal da Convecção ---
    if vel > 0.1 % --- CONVECÇÃO FORÇADA ---
        if strcmp(geometry, 'sphere')
            props_fluid = get_air_props_poly(T_fluid);
            props_surface = get_air_props_poly(Ts);
            mu_s = props_surface.mu;

            Re = vel * D ./ props_fluid.nu;
            Pr = props_fluid.pr;

            Nu = 2 + (0.4 .* Re.^0.5 + 0.06 .* Re.^(2/3)) .* Pr.^0.4 .* (props_fluid.mu ./ mu_s).^0.25;

        elseif strcmp(geometry, 'plate')
            T_film = (Ts + T_fluid) / 2;
            props = get_air_props_poly(T_film);
            Re = vel * D ./ props.nu;
            Nu = 0.664 .* Re.^0.5 .* props.pr.^(1/3);
        else
            Nu = 0;
        end

    else % --- CONVECÇÃO NATURAL ---
        T_film = (Ts + T_fluid) / 2;
        props = get_air_props_poly(T_film);

        DeltaT = abs(Ts - T_fluid);
        if DeltaT < 1e-6, h = 0; return; end

        g = 9.81;
        Ra = (g .* props.beta .* DeltaT .* D.^3) ./ (props.nu .* props.alpha);

        if strcmp(geometry, 'sphere')
            Nu = 2 + (0.589 .* Ra.^(1/4)) ./ (1 + (0.469 ./ props.pr).^(9/16)).^(4/9);
        elseif strcmp(geometry, 'plate')
            switch orientation
                case 'vertical', Nu = (0.825 + (0.387.*Ra.^(1/6)) ./ (1+(0.492./props.pr).^(9/16)).^(8/27)).^2;
                case 'horizontal_up', Nu = 0.15.*Ra.^(1/3);
                case 'horizontal_down', Nu = 0.27.*Ra.^(1/4);
                otherwise, Nu = (0.825 + (0.387.*Ra.^(1/6)) ./ (1+(0.492./props.pr).^(9/16)).^(8/27)).^2;
            end
        else
            Nu = 0;
        end
    end

    props_final = get_air_props_poly((Ts + T_fluid) / 2);
    h = props_final.k .* Nu ./ D;

    if isnan(h) || isinf(h), h = 0; end
end

