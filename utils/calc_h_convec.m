function h = calc_h_convec(D, vel, DeltaT_surface_air)
    % === calc_h_convec.m (Versão com DeltaT Dinâmico) ===
    % Calcula o coeficiente de transferência de calor convectivo.
    % Inputs:
    %   D                - Diâmetro característico [m]
    %   vel              - Velocidade do fluido [m/s]
    %   DeltaT_surface_air - Diferença de temperatura Superfície-Ar [K]
    %                        (usado apenas para convecção natural).
    % Output:
    %   h - Coeficiente convectivo [W/m².K]

    % Propriedades do ar (aproximadas para 300K)
    k_ar = 0.0263;   % Condutividade térmica do ar [W/m.K]
    nu_ar = 1.589e-5;% Viscosidade cinemática do ar [m²/s]
    Pr = 0.707;      % Número de Prandtl
    beta = 1/300;    % Coeficiente de expansão térmica [1/K]
    g = 9.81;        % Aceleração gravitacional [m/s²]

    if vel > 0.1 % Convecção Forçada
        Re = vel * D / nu_ar;
        % Correlação de Churchill e Bernstein para cilindro em fluxo cruzado
        Nu = 0.3 + (0.62 * Re^0.5 * Pr^(1/3)) / (1 + (0.4/Pr)^(2/3))^0.25 * ...
             (1 + (Re/282000)^(5/8))^(4/5);
    else % Convecção Natural
        % Garante que DeltaT seja pelo menos um valor pequeno e positivo.
        DeltaT = max(1e-6, abs(DeltaT_surface_air));

        % Número de Grashof
        Gr = g * beta * DeltaT * D^3 / nu_ar^2;
        % Número de Rayleigh
        Ra = Gr * Pr;

        % Correlação de Churchill e Chu para placa vertical/cilindro
        Nu = (0.6 + (0.387 * Ra^(1/6)) / (1 + (0.559/Pr)^(9/16))^(8/27))^2;
    end

    % Calcula o coeficiente convectivo a partir do Nusselt
    h = Nu * k_ar / D;
end

