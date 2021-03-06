%% predict_my_pet
% Obtains predictions, using parameters and data

%%
function [Prd_data, info] = predict_Pseudemydura_umbrina(par, chem, T_ref, data)
  % created by Starrlight Augustine, Dina Lika, Bas Kooijman, Goncalo Marques and Laure Pecquerie 2015/01/30
  
  %% Syntax
  % [Prd_data, info] = <../predict_my_pet.m *predict_my_pet*>(par, chem, data)
  
  %% Description
  % Obtains predictions, using parameters and data
  %
  % Input
  %
  % * par: structure with parameters (see below)
  % * chem: structure with biochemical parameters
  % * data: structure with data (not all elements are used)
  %  
  % Output
  %
  % * Prd_data: structure with predicted values for data
  
  %% Remarks
  % Template for use in add_my_pet
  
  %% unpack par, chem, cpar and data
  cpar = parscomp_st(par, chem);
  v2struct(par); v2struct(chem); v2struct(cpar);
  v2struct(data);
  %k_J=k_M;
  pars_T=[T_A,T_L,T_H,T_AL,T_AH];
  %% compute temperature correction factors
  TC_ab = tempcorr(temp.ab, T_ref, pars_T);
  TC_ap = tempcorr(temp.ap, T_ref, pars_T);
  TC_am = tempcorr(temp.am, T_ref, pars_T);
  TC_Ri = tempcorr(temp.Ri, T_ref, pars_T);
%  TC_tL = tempcorr(temp.tL, T_ref, pars_T);

  %% zero-variate data

  % life cycle
  pars_tp = [g* s_Megg; k; l_T; v_Hb; v_Hp];               % compose parameter vector (note s_Megg factor applied - egg in depression)
  [t_p, t_b, l_p, l_b, info] = get_tp(pars_tp, f); % -, scaled times & lengths at f
  
  % birth
  L_b = L_m * l_b;                  % cm, structural length at birth at f
  Lw_b = L_b/ del_M;                % cm, physical length at birth at f
  Wd_b = L_b^3 * 0.5 * (1 + f * w); % g, dry weight at birth at f (remove d_V for wet weight)
  aT_b = t_b/ (k_M * s_M * 1.2) / TC_ab;           % d, age at birth at f and T (note s_M factor applied - egg in depression)

   pars_tp = [g ; k; l_T; v_Hb; v_Hp];               % compose parameter vector 
  [t_p, t_b, l_p, l_b, info] = get_tp(pars_tp, f); % -, scaled times & lengths at f
  
  % puberty 
  L_p = L_m * l_p;                  % cm, structural length at puberty at f
  Lw_p = L_p/ del_M;                % cm, physical length at puberty at f
  Wd_p = L_p^3 * d_V * (1 + f * w); % g, dry weight at puberty (remove d_V for wet weight)
  %aT_p = t_p/ TC_ap;           % d, age at puberty at f and T
  % code to simulate growth under fluctuating temperature and food (pond duration)
  years=100; % years to simulate
  days=sort(repmat(1:182:364*years,1,2)); % set up pond durations of 182 days, and dry periods of the same length (one day short of year!)
  act=repmat([1 1 0 0 ],[1,years]); % activity states
  tf=vertcat(days,act)'; % vector of hydroperiods/dry periods lasting 182 days
  tR=1:365:years*365; % intervals to get reproduction output
  TC_f=0.2944; % temp correction factor when in water
  TC_0=1.36442; % temp correction factor when on land
  t=1:(365*years); % vector of days to simulate
  eLHR0 = [f; L_b; g * s_M * u_Hb/ l_b^3; 0]; % initial scaled reserve, length, scaled maturity density and reproduction buffer (birth)
  pars_UE0 = [V_Hb; g * s_M; k_J * s_M * 1.2; k_M * s_M * 1.2; v * s_M * 1.2]; U_E0 = initial_scaled_reserve(0.8, pars_UE0);
  [t eLHR] = ode45(@dget_eLHR, t, eLHR0, [], s_M, kap, u_Hp, k_J, v, g, L_m, f, TC_f, TC_0, tf); 
  e = eLHR(:,1); L = eLHR(:,2); H = eLHR(:,3); eR = eLHR(:,4); teR = [t, eR];
  EW = L .^ 3 .* (1 + (e + eR) * w); % wet mass, g 
  ER = L .^ 3 .* eR * w;              % reproduction buffer, g
  ER2 = horzcat(ER,cat(1,ER(2:length(ER)),0)); % set up vector of repro buffer, offset to get daily diff
  ER2 = ER2(:,2)-ER2(:,1);        % daily diffs in repro buffer, g
  EW2 = L .^ 3 .* (1 + (e) * w);  % non-reproductive wet mass, g
  eLHR_pub=eLHR(eLHR(:,4)==0,:);   % get vector up to puberty
  pubeLHR=eLHR_pub(end,:);           % get last values of vector up to puberty
 % L_p=pubeLHR(2);                  % cm, structural length at puberty at f
 % Lw_p = L_p/ del_M;               % cm, physical length at puberty at f
 % Wd_p = max(eLHR_pub(:,2).^ 3 .*(1+eLHR_pub(:,1)*w))* d_V; % g, dry weight at puberty 
  aT_p=length(eLHR_pub);           % d, age at puberty at f and T
  E_0 = p_Am * TC_ab * U_E0;       % energy of egg, J
  RT_i = mean(ER2(length(ER2)-375:length(ER2)-10))/(E_0/mu_E*w_E/d_V);   % #/d, ultimate reproduction rate at T over last year of simulation(divide by wet mass of egg)
%   L_i = max(L);                    % cm, ultimate structural length at f
%   Lw_i= L_i/del_M;                 % cm, ultimate physical length at f
%   Wd_i = max(EW2)* d_V;                  % g, ultimate dry weight (remove d_V for wet weight)
  

  if size(tW,2)==2
  tWeight = tW(:,1);
  else
   tWeight = round(tW);
  end
  [j i] = ismember(tWeight, t); EW1 = L(i) .^ 3 .* (1 + (e(i)) * w);

   
  years=100; % years to simulate
  days=sort(repmat(1:182:364*years,1,2)); % set up pond durations of 182 days, and dry periods of the same length (one day short of year!)
  act=repmat([1 1 0 0 ],[1,years]); % activity states
  tf=vertcat(days,act)'; % vector of hydroperiods/dry periods lasting 182 days
  tR=1:365:years*365; % intervals to get reproduction output
  TC_f=0.2944; % temp correction factor when in water
  TC_0=1.36442; % temp correction factor when on land
  t=1:(365*years); % vector of days to simulate
  eLHR0 = [f; L_b; g * s_M * u_Hb/ l_b^3; 0]; % initial scaled reserve, length, scaled maturity density and reproduction buffer (birth)
  pars_UE0 = [V_Hb; g * s_M * 1.2; k_J * s_M * 1.2; k_M * s_M * 1.2; v * s_M * 1.2]; U_E0 = initial_scaled_reserve(0.8, pars_UE0);
  [t eLHR] = ode45(@dget_eLHR, t, eLHR0, [], s_M, kap, u_Hp, k_J, v, g, L_m, f, TC_f, TC_0, tf); 
  e = eLHR(:,1); L = eLHR(:,2); H = eLHR(:,3); eR = eLHR(:,4); teR = [t, eR];
 
  if size(tL,2)==2
  tLength = tL(:,1);
  else
   tLength = round(tL);
  end
  [j i] = ismember(tLength, t); EL = L(i)/ del_M; EW = L(i) .^ 3 .* (1 + (e(i)) * w);

  
  
  %EW = horzcat(EL(:,1),EW(:,1));
  %Wd_i = L_i^3 * d_V * (1 + f * w); % g, ultimate dry weight (remove d_V for wet weight)
  % ultimate
  l_i = f - l_T;                    % -, scaled ultimate length at f
  L_i = L_m * l_i;                  % cm, ultimate structural length at f
  Lw_i = L_i/ del_M;                % cm, ultimate physical length at f
  Wd_i = L_i^3 * d_V * (1 + f * w); % g, ultimate dry weight (remove d_V for wet weight)
%  
%   % reproduction
  pars_R = [kap; kap_R; g; k_J; k_M; L_T; v; U_Hb; U_Hp]; % compose parameter vector at T
  RT_i = TC_f * reprod_rate(L_i, f, pars_R);             % #/d, ultimate reproduction rate at T

  % life span
  pars_tm = [g; l_T; h_a/ k_M^2; s_G];  % compose parameter vector at T_ref
  t_m = get_tm_s(pars_tm, f, l_b);      % -, scaled mean life span at T_ref
  aT_m = t_m/ k_M/ TC_am;               % d, mean life span at T
  
  %% pack to output
  % the names of the fields in the structure must be the same as the data names in the mydata file
  Prd_data.ab = aT_b;
  Prd_data.ap = aT_p;
  Prd_data.am = aT_m;
  Prd_data.Lb = Lw_b;
  Prd_data.Lp = Lw_p;
  Prd_data.Li = Lw_i;
  Prd_data.Wdb = Wd_b;
  Prd_data.Wdp = Wd_p;
  Prd_data.Wdi = Wd_i;
  Prd_data.Ri = RT_i;
  
  % O2-temperature
    f = 1;
  % yield coefficients  
  y_E_X = kap_X * mu_X/ mu_E;      % mol/mol, yield of reserve on food
  y_X_E = 1/ y_E_X;                % mol/mol, yield of food on reserve
  y_V_E = mu_E * M_V/ E_G;         % mol/mol, yield of structure on reserve
  y_P_X = kap_P * mu_X/ mu_P;    % mol/mol, yield of faeces on food 
  y_P_E = y_P_X/ y_E_X;            % mol/mol, yield of faeces on reserve
  % mass-power couplers
  eta_XA = y_X_E/mu_E;             % mol/kJ, food-assim energy coupler
  eta_PA = y_P_E/mu_E;             % mol/kJ, faeces-assim energy coupler
  eta_VG = y_V_E/mu_E;             % mol/kJ, struct-growth energy coupler
  eta_O = [-eta_XA  0       0;     % mol/kJ, mass-energy coupler
    	   0        0       eta_VG;% used in: J_O = eta_O * p
	     1/mu_E  -1/mu_E   -1/mu_E;
         eta_PA     0       0]; 
  O2M = (- n_M\n_O)'; % -, matrix that converts organic to mineral fluxes  O2M is prepared for post-multiplication eq. 4.35

  p_ref = p_Am * L_m^2;               % J/d, max assimilation power at max size
  pars_power = [kap; kap_R; g*s_MO2; k_J*s_MO2; k_M*s_MO2; L_T*s_MO2; v; U_Hb; U_Hp];
  X_gas = (0.082058*(20+273.15))/(0.082058*293.15)*24.06;  % gas correction factor
  
  % Mean of all turtles
  o2Ww=302.325;
  L = ((o2Ww*.3)/ d_V/ (1 + f * w)).^(1/3); % cm, structural length, use dry mass for 362.4 g wet mass
  pACSJGRD = p_ref * scaled_power(L, f, pars_power, l_b, l_p);
  pADG = pACSJGRD(:, [1 7 5]);  pADG(:,1) = 0; % exclude assim contribution
  JM = pADG * eta_O' * O2M;                     % mol/d, mineral fluxes
  EO = (- 1 * (JM(:,3) * X_gas) .* tempcorr(273+TO(:,1), T_ref, pars_T))/o2Ww/24*1000;
  
  Prd_data.TO = EO;
  Prd_data.tL = EL;
  Prd_data.LW = EW;
  Prd_data.tW = EW1;
  
  
function dL = dget_L (t, L, L_i, r_B, T_ref, T_A, tT)
 T = spline1(t, tT);                   % C, temp at t
 TC = tempcorr(273 + T, T_ref, T_A);   % -, Temperature Correction factor
 dL = TC * r_B * (L_i - L);            % cm/d, change in length

function deLHR = dget_eLHR (t, eLHR, sM, kap, uHp, kJ, v, g, L_m, f_zoo, TC_f, TC_0, tf)
  e = eLHR(1); L = eLHR(2); eH = eLHR(3); eR = eLHR(4); eHp = uHp * g * L_m^3/ L^3;
  if spline0(t,tf) % active
    %if eH < eHp  
    % TC = TC_f; f = f_zoo; L_mt = L_m * sM;
    % v2 = v / sM;
    % kJ2 = kJ / sM;
   % else
     TC = TC_f; f = f_zoo; L_mt = L_m;
     v2 = v;
     kJ2 = kJ; 
   %end
  else % torpor
    TC = TC_0; f = 0; L_mt = L_m/ sM; % correct for low maint during torpor
    v2 = v * sM;
    kJ2 = kJ * sM;
  end
  de = TC * v2 * (f - e)/ L;              % 1/d, change in scaled reserve density
  r = TC * v2 * (e/ L - 1/ L_mt)/ (e + g); % 1/d, spec growth rate
  dL = L * r/ 3;                         % cm/d, change in length
  if eH < eHp %|| t < 3000
    deH = TC * max(0,(1 - kap) * e * (TC * v2/ L - r) - eH * (TC * kJ2 + r)); % 1/d, change in scaled maturity
    deR = 0; 
  else
    deH = 0;
    deR = TC * max(0, (1 - kap) * e * (TC * v2/ L - r) - eHp * TC * kJ2 - r * eR); % 1/d, change in scaled reprod buffer
  end
  deLHR = [de; dL; deH; deR];

function f = spline0(t,tf)
  f = tf(sum(t>=tf(:,1)),2);
          
function eR = spawn(teR, t1, eR1)
  n = length(t1); eR = eR1;
  for i = 0:n-1
    eR(n-i) = eR(n-i) - teR(end,2);
    if eR(n-i) < 0
        eR(n-i) = 0;
    end
    if teR(end,1) >= t1(n-i)
        teR(end,:) = [];
    end
  end
