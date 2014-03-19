%% Generate Iterated-Rippled Noise stimulus

Fs = 96000;

t = 0:1/Fs:5-1/Fs;

noise = randn(1,length(t));



%% Create IRN
niter = 16;
tshift = 2.5;  % time shift in milliseconds

tshift = tshift / 1000;

sshift = round(Fs * tshift);

iternoise = [noise zeros(1,sshift*niter)];

for k = sshift:sshift:sshift*niter   
    iternoise(k:k+length(noise)-1) = iternoise(k:k+length(noise)-1) + noise;   
end

titer = (0:length(iternoise)-1) / Fs;



%% Cut out subset
cutstart  = 1; % in seconds
cutfinish = 1.4;

ind = titer >= cutstart & titer < cutfinish;

subiternoise = iternoise(ind);
subtiter     = titer(ind);


% Gate subset
ramptime = 0.001; % in seconds

rampsamp = round(ramptime * Fs);

lingate = linspace(0,1,rampsamp);

subiternoise(1:rampsamp)         = subiternoise(1:rampsamp) .* lingate;
subiternoise(end-rampsamp+1:end) = subiternoise(end-rampsamp+1:end) .* fliplr(lingate);

%% Create control IRNo (Barker et al, 2012)

windur = 0.0025; % in seconds

k = round(Fs * windur);

% stepsize = round(k/2);
stepsize = k;

IRNo = zeros(size(subiternoise));
testIR = zeros(size(subiternoise));
for i = 1:stepsize:length(subiternoise)-stepsize
    
    tempIRNo = subiternoise(i:i+stepsize-1);
    
    tempIRNo = fft(tempIRNo);
    
    mag = abs(tempIRNo);
    theta = angle(tempIRNo);
    
    theta = theta(randperm(stepsize)); 
    rt = mag.*cos(theta);
    theta = theta(randperm(stepsize));
    it = mag.*sin(theta);
    
    testIR(i:i+stepsize-1) = ifft(complex(rt,it));
           
    tempIRNo = complex(rt,it);
        
    IRNo(i:i+stepsize-1) = ifft(tempIRNo, 'symmetric');
    
end

 IRNo = IRNo / max(IRNo) * 0.9999;

%% Band-pass filtering

Fpass1 = 9170.040435;  % First Passband Frequency
Fpass2 = 10905.07733;  % Second Passband Frequency
Fstop1 = Fpass1*2^-1;       % First Stopband Frequency
Fstop2 = Fpass2*2^1;        % Second Stopband Frequency
Astop1 = 24;           % First Stopband Attenuation (dB)
Apass  = 1;            % Passband Ripple (dB)
Astop2 = 24;           % Second Stopband Attenuation (dB)
match  = 'passband';   % Band to match exactly

% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
                      Astop2, Fs);
Hd = design(h, 'butter', 'MatchExactly', match);

IRNo = filter(Hd,IRNo);
subiternoise = filter(Hd,subiternoise);

 
 

%% IRN Final
zerodur = 0.1; % in seconds
nreps   = 10;  % number of repetitions

zerosamp = round(zerodur * Fs);

zeronum = zeros(1,zerosamp);

tempsig = [subiternoise, zeronum];

IRNfinal = [];
for i = 1:nreps
    IRNfinal = [IRNfinal, tempsig];
end

IRNfinal = IRNfinal / max(abs(IRNfinal)) * 0.9999;

timefinal = (0:length(IRNfinal)-1) / Fs;


%% IRNo Final
zerodur = 0.1; % in seconds
nreps   = 10;  % number of repetitions

zerosamp = round(zerodur * Fs);

zeronum = zeros(1,zerosamp);

tempsig = [IRNo, zeronum];

IRNofinal = [];
for i = 1:nreps
    IRNofinal = [IRNofinal, tempsig];
end

IRNofinal = IRNofinal / max(abs(IRNofinal)) * 0.9999;


%% Plot spectrograms
subplot(211)
spectrogram(IRNofinal,256,200,2048,Fs,'yaxis')
colorbar
title('IRNo')

subplot(212)
spectrogram(IRNfinal,256,200,2048,Fs,'yaxis')
colorbar
title('IRN')

%% listen to IRN/IRNo
disp('IRN')
soundsc(IRNfinal,Fs);

disp('IRNo')
soundsc(IRNofinal,Fs);

%% Plot data
subplot(211)
% L = length(IRNo);
% y = IRNo;

subplot(212)
L = length(subiternoise);
y = subiternoise;

NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y.*hann(L)',NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);

% Plot single-sided amplitude spectrum.
plot(f,db(2*abs(Y(1:NFFT/2+1)))) 
title('Single-Sided Amplitude Spectrum of y(t)')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')

xlim([1 20000])
set(gca,'yscale','log')




%% Export as WAV file


[filename,pathname] = uiputfile({'*.wav','WAV file (*.wav)'},'Save IRN');
audiowrite(fullfile(pathname,filename),IRNfinal,Fs,'Title','IRN','Artist','Blake Butler, PhD')


[filename,pathname] = uiputfile({'*.wav','WAV file (*.wav)'},'Save IRNo');
audiowrite(fullfile(pathname,filename),IRNofinal,Fs,'Title','IRNo','Artist','Blake Butler, PhD')








