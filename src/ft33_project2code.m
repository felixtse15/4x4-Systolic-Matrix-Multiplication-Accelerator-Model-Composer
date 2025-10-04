clear; clc; close all;

N = 4; % Size of matrix

num_multiplications = 2;

% 'matrix-matrix' or 'matrix-vector'
multiplication_mode = 'matrix-vector';

% Initialize cell arrays
A_matrices = cell(1, num_multiplications);
B_matrices = cell(1, num_multiplications);

% Generate random input matrices based on the selected mode
fprintf('Mode: %s\n\n', multiplication_mode);
for m = 1:num_multiplications
    A_matrices{m} = randi([-20, 20], N, N);
    
    % Generate B as either a matrix or vector ---
    if strcmp(multiplication_mode, 'matrix-vector')
        % For matrix-vector mode, generate a single 4x1 column vector.
        B_matrices{m} = randi([-20, 20], N, 1);
    else
        % For matrix-matrix mode, generate a full 4x4 matrix.
        B_matrices{m} = randi([-20, 20], N, N);
    end
    
    fprintf('Generated A%d\n', m);
    disp(A_matrices{m});
    fprintf('Generated B%d\n', m);
    disp(B_matrices{m});
end

% Timing parameters are conditional based on the mode
if strcmp(multiplication_mode, 'matrix-vector')
    % Computation finishes in the first column at cycle 10 (t=9).
    latency_to_compute = 10;
    % A new operation can start as soon as the first column is free.
    initiation_interval = 10;
else
    % Computation finishes across the whole array at cycle 13 (t=12).
    latency_to_compute = 13;
    % A new operation can start after the full computation phase.
    initiation_interval = 13;
end

unload_duration = N;
% Total time to fully unload the first operation's data
first_op_finish_time = (latency_to_compute - 1) + unload_duration;
% Calculate total simulation time for the full pipeline
total_cycles = (num_multiplications - 1) * initiation_interval + first_op_finish_time;

% Calculate all expected results for verification.
C_expected_matrices = cell(1, num_multiplications);
fprintf('\n');
for m = 1:num_multiplications
    C_expected_matrices{m} = A_matrices{m} * B_matrices{m};
    fprintf('Expected Result Matrix C%d\n', m);
    disp(C_expected_matrices{m});
end

t = (0:total_cycles - 1)';

A_signals = cell(1, N);
B_signals = cell(1, N);
for i = 1:N
    A_signals{i} = zeros(length(t), 1);
    B_signals{i} = zeros(length(t), 1);
end
sel_signal = zeros(length(t), 1);
reset_signal = zeros(length(t), 1);

for m = 1:num_multiplications
    % Start time of current operation offset by pipeline interval
    start_time_offset = (m - 1) * initiation_interval;
    
    current_A = A_matrices{m};
    current_B = B_matrices{m};
    
    % Skew input data for current operation
    for i = 1:N
        rowData = current_A(i, :);
        start_idx = start_time_offset + i;
        end_idx = start_idx + N - 1;
        A_signals{i}(start_idx : end_idx) = rowData;
    end
    
    % Handle B as either a vector or a matrix ---
    for j = 1:N
        if j > size(current_B, 2)
            colData = zeros(N, 1);
        else
            colData = current_B(:, j);
        end
        
        start_idx = start_time_offset + j;
        end_idx = start_idx + N - 1;
        B_signals{j}(start_idx : end_idx) = colData;
    end
    
    % Control signals 
    reset_time_idx = start_time_offset + latency_to_compute;
    reset_signal(reset_time_idx) = 1;
   
    sel_start_idx = reset_time_idx;
    sel_end_idx = sel_start_idx + unload_duration - 1;
    sel_signal(sel_start_idx:sel_end_idx) = 1;
end

for i = 1:N
    varName = sprintf('A%d_ts', i);
    eval([varName '.time = t;']);
    eval([varName '.signals.values = A_signals{i};']);
    eval([varName '.signals.dimensions = 1;']);
end
for j = 1:N
    varName = sprintf('B%d_ts', j);
    eval([varName '.time = t;']);
    eval([varName '.signals.values = B_signals{j};']);
    eval([varName '.signals.dimensions = 1;']);
end
sel_ts.time = t; reset_ts.time = t;
sel_ts.signals.values = sel_signal; reset_ts.signals.values = reset_signal;
sel_ts.signals.dimensions = 1; reset_ts.signals.dimensions = 1;

out = sim('ft33_project2_copy', total_cycles); 

for m = 1:num_multiplications
    start_time_offset = (m - 1) * initiation_interval;
    
    result_available_idx = start_time_offset + (latency_to_compute - 1) + unload_duration;
    
    C_sim_full_result = zeros(N, N);
    C_sim_full_result(1, :) = flip(out.C1(result_available_idx - N + 1 : result_available_idx));
    C_sim_full_result(2, :) = flip(out.C2(result_available_idx - N + 1 : result_available_idx));
    C_sim_full_result(3, :) = flip(out.C3(result_available_idx - N + 1 : result_available_idx));
    C_sim_full_result(4, :) = flip(out.C4(result_available_idx - N + 1 : result_available_idx));
    
    % Process the result based on the mode
    if strcmp(multiplication_mode, 'matrix-vector')
        C_sim_result = C_sim_full_result(:, 1);
    else
        C_sim_result = C_sim_full_result;
    end
    
    fprintf('\nC Simulation Result #%d\n', m);
    disp(C_sim_result);
    
    % This error calculation now works for both cases:
    error = C_expected_matrices{m} - C_sim_result;
    fprintf('\nError #%d\n', m);
    disp(error);
end

