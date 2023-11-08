% Generate a time table of CSI bit stream indexing. 
% Corresponding to the "TWO-LANE RAW10 TRANSMISSION MODEL" in Appendix A
function res_csi = f_csi_time2bit(num_points, fs)


    point = (1:num_points)' ;

    t_0 = 0; 
    t_s = point / fs; 
    
    
    % Hard-coded parameters for rpi cam v1
    N_r = 1080; N_c = 1920; N_b = 10;
    T_fs = 33311610/1e9;
    T_rs = 29590/1e9;
    T_bs = 1/408e6;   
    T_B = 8*T_bs;  
    
    i_f = floor((t_s-t_0)/T_fs);
    
    i_r = floor((t_s-t_0-T_fs*i_f)/T_rs);
    i_r(i_r >= N_r) = -inf;
    
    t_til = max(0, t_s - t_0 - T_fs*i_f - T_rs*i_r);  
    
    s_c = 8*floor(t_til/ 5/ T_B);
    g_B = mod(floor(t_til/T_B), 5);
    
    i_c0 = s_c +(g_B<2).*(2*g_B) + (g_B>2).*(2*g_B-1) + ...
                (g_B==2).*mod(floor(t_til/2/T_bs), 4);
    i_c0(i_c0 >= N_c) = -inf;
    
    i_c1 = s_c +(g_B<2).*(2*g_B+1) + ((g_B>=2)&(g_B<4)).*(2*g_B) + ...
                (g_B==4).*(4+mod(floor(t_til/2/T_bs), 4));
    i_c1(i_c1 >= N_c) = -inf;
    
    i_b0 = (g_B~=2).*(2+mod(floor(t_til/T_bs), 8)) + ...
                (g_B==2).*mod(floor(t_til/T_bs), 2);
    i_b0(i_b0 > N_b) = -inf;
    
    i_b1 = (g_B~=4).*(2+mod(floor(t_til/T_bs), 8)) + ...
                (g_B==4).*mod(floor(t_til/T_bs), 2);
    i_b1(i_b1 > N_b) = -inf;
    
    valid = (i_r>-inf).*(i_c0>-inf);
    
    res_csi = array2table([t_s, i_f, i_r, i_c0, i_b0, i_c1, i_b1, valid], ...
        'VariableNames',{'time', 'i_f', 'i_r', 'i_c0', 'i_b0',  'i_c1', 'i_b1', 'valid'});
    
end