function G = radiacao_solar(t)
    % --- radiacao_solar.m ---
    % Calcula a irradiância solar incidente (W/m²) em diferentes superfícies
    % com base na hora do dia. Modelo simplificado para um dia claro no equador.
    %
    % Inputs:
    %   t - Tempo de simulação em segundos
    %
    % Outputs:
    %   G - Struct com a irradiância para cada superfície (G.teto, G.leste, etc.)

    hora_do_dia = mod(t / 3600, 24); % Hora do dia (0-24)

    % Define o período do dia com sol (aproximadamente 6h às 18h)
    nascer_do_sol = 6;
    por_do_sol = 18;
    duracao_dia = por_do_sol - nascer_do_sol; % 12 horas

    % Inicializa a irradiância como zero (para a noite)
    G.teto = 0;
    G.leste = 0;
    G.oeste = 0;
    G.sul = 0;
    G.norte = 0;

    % A radiação solar só é calculada durante o período diurno
    if hora_do_dia > nascer_do_sol && hora_do_dia < por_do_sol
        % Ângulo que varia de 0 a pi, representando o progresso do dia
        angulo_solar = pi * (hora_do_dia - nascer_do_sol) / duracao_dia;

        % Irradiância na superfície horizontal (teto)
        % Modelo senoidal com pico de 950 W/m² ao meio-dia
        G_max_horiz = 950;
        G.teto = G_max_horiz * sin(angulo_solar);

        % Irradiância em superfícies verticais (modelo simplificado)
        G_max_vert = 600; % Pico de irradiância para paredes verticais

        % Parede Leste: recebe sol pela manhã (6h às 12h)
        if hora_do_dia < 12
            angulo_manha = pi * (hora_do_dia - nascer_do_sol) / (duracao_dia / 2);
            G.leste = G_max_vert * sin(angulo_manha);
        end

        % Parede Oeste: recebe sol pela tarde (12h às 18h)
        if hora_do_dia >= 12
            angulo_tarde = pi * (hora_do_dia - 12) / (duracao_dia / 2);
            G.oeste = G_max_vert * sin(angulo_tarde);
        end

        % Paredes Norte e Sul: recebem principalmente radiação difusa
        % Modelado como uma fração da radiação horizontal
        fator_difuso = 0.2;
        G.sul = fator_difuso * G.teto;
        G.norte = fator_difuso * G.teto; % Para o compartimento do reservatório
    end
end

