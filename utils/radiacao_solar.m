function G = radiacao_solar(t, p)
    % --- radiacao_solar.m (Modelo Físico Avançado - Ângulos Solares Rigorosos) ---
    % Versão final com cálculo explícito dos ângulos de altitude, azimute e
    % incidência para a máxima precisão física.

    hora_do_dia = mod(t / 3600, 24);

    nascer_do_sol = 6; por_do_sol = 18; duracao_dia = por_do_sol - nascer_do_sol;
    G = struct('teto',0,'leste',0,'oeste',0,'sul',0,'norte',0);

    if hora_do_dia <= nascer_do_sol || hora_do_dia >= por_do_sol, return; end

    % --- 1. CÁLCULO DOS ÂNGULOS SOLARES FUNDAMENTAIS ---
    omega = (pi/duracao_dia) * (hora_do_dia - 12);
    delta = 0; phi = 0;

    sin_alpha_s = max(0, sin(phi)*sin(delta) + cos(phi)*cos(delta)*cos(omega));
    alpha_s = asin(sin_alpha_s);
    if alpha_s < 1e-6, return; end

    cos_gamma_s = min(1, max(-1, (sin_alpha_s*sin(phi) - sin(delta)) / (cos(alpha_s)*cos(phi))));
    gamma_s = acos(cos_gamma_s);
    if omega > 0, gamma_s = -gamma_s; end

    % --- 2. MODELO ASHRAE PARA RADIAÇÃO EM CÉU LIMPO ---
    A = p.rad_A; B = p.rad_B; C = p.rad_C;
    G_beam_normal = A * exp(-B / sin_alpha_s);
    G_diffuse_horiz = C * G_beam_normal;

    % --- 3. CÁLCULO DA RADIAÇÃO TOTAL NA HORIZONTAL (TETO) ---
    G_beam_horiz = G_beam_normal * sin_alpha_s;
    G_total_horiz = G_beam_horiz + G_diffuse_horiz;
    G.teto = G_total_horiz;

    % --- 4. CÁLCULO DA RADIAÇÃO TOTAL NAS PAREDES VERTICAIS ---
    G_diffuse_sky_vert = 0.5 * G_diffuse_horiz;
    G_reflected_ground_vert = 0.5 * G_total_horiz * p.albedo_solo;

    function G_beam_wall = get_beam_on_wall(wall_azimuth)
        cos_theta = cos(alpha_s) * cos(gamma_s - wall_azimuth);
        if cos_theta > 0, G_beam_wall = G_beam_normal * cos_theta; else, G_beam_wall = 0; end
    end

    azimuth_leste = pi/2; azimuth_oeste = -pi/2; azimuth_sul = 0; azimuth_norte = pi;

    G.leste = get_beam_on_wall(azimuth_leste) + G_diffuse_sky_vert + G_reflected_ground_vert;
    G.oeste = get_beam_on_wall(azimuth_oeste) + G_diffuse_sky_vert + G_reflected_ground_vert;
    G.sul   = get_beam_on_wall(azimuth_sul)   + G_diffuse_sky_vert + G_reflected_ground_vert;
    G.norte = get_beam_on_wall(azimuth_norte) + G_diffuse_sky_vert + G_reflected_ground_vert;

end

