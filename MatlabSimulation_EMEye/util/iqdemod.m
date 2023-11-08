function res = iqdemod(xx, fc, fb, fs)

    xx = bandpass(xx, [fc-fb/2, fc+fb/2],...
        fs, 'Steepness', 1);
    
    ii = xx.*sin( 2*pi*fc* (1:length(xx))/fs )';
    qq = xx.*sin( 2*pi*fc* (1:length(xx))/fs + pi/2)';
    
    
    res = sqrt(ii.^2 + qq.^2);

end