% === power_profile.m ===
function Pel = power_profile(t)
    % Define o perfil de potência elétrica ao longo do tempo (em segundos)
    % baseado na Tabela 2 do enunciado

    hora = t / 3600;  % converter segundos para horas

    perfil = [...
        0  0;
        1  0;
        2  0;
        3  0;
        4  0;
        5  0;
        6  50;
        7  50;
        8  60;
        9  80;
        10 80;
        11 60;
        12 30;
        13 50;
        14 90;
        15 50;
        16 50;
        17 90;
        18 95;
        19 60;
        20 50;
        21 30;
        22 0;
        23 0;
        24 0];

    if hora <= 0
        Pel = 0;
    elseif hora >= 24
        Pel = 0;
    else
        h1 = floor(hora);
        h2 = ceil(hora);
        P1 = perfil(h1+1,2);
        P2 = perfil(h2+1,2);
        frac = hora - h1;
        Pel = (1 - frac) * P1 + frac * P2; % interpolação linear
    end

    Pel = Pel * 1e3; % converter kW para W
end

