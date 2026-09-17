clear;
clc;
close all;

%% ============================================================
%  LIF GOLDEN MODEL
%  Leaky Integrate-and-Fire neuron
% =============================================================

%% Parameters

tau_m   = 10e-3;     % Membrane time constant [s]
V_leak  = 0.0;      % Leak potential [V]
V_reset = 0.0;      % Reset potential [V]
V_th    = 1.0;      % Spike threshold [V]

R_m     = 100e6;     % Membrane resistance [Ohm]
C_m     = 100e-12;   % Membrane capacitance [F]

T_ref   = 1e-3;      % Refractory period [s]

%% Simulation parameters

dt = 1e-5;           % Simulation timestep [s]
T  = 0.2;            % Total simulation time [s]

t = 0:dt:T;
N = length(t);

%% Input current

I_in = 12e-9 * ones(1,N);   % Constant input current [A]

%% Initial conditions

V_m = zeros(1,N);
spike = zeros(1,N);

V_m(1) = V_reset;

refractory_timer = 0;

%% ============================================================
%  Simulation
% =============================================================

for k = 2:N

    % Refractory period
    if refractory_timer > 0

        V_m(k) = V_reset;
        refractory_timer = refractory_timer - dt;

    else

        % LIF differential equation:
        %
        % dV/dt = (-(V-V_leak) + R*I) / tau

        dV = (-(V_m(k-1) - V_leak) ...
              + R_m * I_in(k)) / tau_m;

        % Euler integration
        V_m(k) = V_m(k-1) + dt*dV;

        % Threshold detection
        if V_m(k) >= V_th

            spike(k) = 1;

            V_m(k) = V_reset;

            refractory_timer = T_ref;
        end
    end
end

%% ============================================================
%  Plot membrane potential
% =============================================================

figure;

plot(t*1e3, V_m, 'b', 'LineWidth', 1.5);
hold on;

yline(V_th, '--r', 'V_{th}', 'LineWidth', 1.2);

xlabel('Time [ms]');
ylabel('Membrane potential V_m [V]');

title('LIF Neuron - Membrane Potential');

grid on;

%% ============================================================
%  Plot spikes
% =============================================================

figure;

stem(t*1e3, spike, 'k', 'Marker', 'none');

xlabel('Time [ms]');
ylabel('Spike');

title('LIF Neuron - Spike Output');

ylim([-0.1 1.2]);

grid on;

%% ============================================================
%  Print basic results
% =============================================================

spike_times = t(spike == 1);

fprintf('\n');
fprintf('========================================\n');
fprintf('       LIF GOLDEN MODEL RESULTS\n');
fprintf('========================================\n');

fprintf('Input current      = %.2f nA\n', I_in(1)*1e9);
fprintf('Tau_m              = %.2f ms\n', tau_m*1e3);
fprintf('Threshold          = %.2f V\n', V_th);
fprintf('Number of spikes   = %d\n', length(spike_times));

if length(spike_times) > 1

    ISI = diff(spike_times);

    fprintf('Mean ISI           = %.2f ms\n', mean(ISI)*1e3);
    fprintf('Mean firing rate   = %.2f Hz\n', 1/mean(ISI));

end

fprintf('========================================\n');
