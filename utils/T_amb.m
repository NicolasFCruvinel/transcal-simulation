function T = T_amb(t)
  hora = t / 3600;
  T = 28 + 5 * sin(2 * pi * (hora - 12) / 24) + 273.15;
end
