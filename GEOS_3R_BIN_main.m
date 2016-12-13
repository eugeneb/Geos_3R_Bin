clear
clc

%fclose(instrfind)

%fead_data_from='GEOS';
fead_data_from='file';

if (fead_data_from=='GEOS')      % ��������� �� �����
    Num_com_port = 'COM67';   
    baud = 115200;
    stream = serial(Num_com_port, 'BaudRate', baud);
else                             % ������ �� �����
    name_bin_file = 'bin_data_file/geos_3MR_F_1_Hz.bin';
    stream = fopen(name_bin_file, 'r');
end


% ��� ������������
phData.NumPoint = 1000;          % ������������ ����� ����� �� �������
phData.NumPointPoiskKA=5;        % ����� ����� ��� ������ ������� ��
phData.SatMax = 96;       % ����� ��������� 

% ���������:
F0_gps=1.57542e9;                % ����������� ������� gps
F0_gln=1.602e9;                  % ����������� ������� �������
dF_gln=562500;                   % ��� �� ������� ������� (���, ������)
c=299792458;                     % �������� �����

% ��������� ������ ��� ������� ��� ������
phData.reliable(1:phData.NumPoint,1:phData.SatMax) = nan; 
phData.SNR(1:phData.NumPointPoiskKA,1:phData.SatMax) = nan;
phData.phase(1:phData.NumPoint,1) = nan;
phData.time(1:phData.NumPoint,1) = nan;
phData.H_liter = nan;
phData.range(1:phData.NumPoint,1) = nan;
phData.ADR(1:phData.NumPoint,1) = nan;
phData.cycle_d(1:phData.NumPoint,1) = nan;
t_gps(1:phData.NumPoint,1) = nan;

if(fead_data_from=='GEOS')       % ��� ��� GEOS-3R
                                 % ��������� ��������� ��������� ���������
                                 % ������ ��������� 0�10 � 0x13

    % �������� ������ 0x4F - ���������� �������� ���������
    Bin.data_write(1:8,1)=[hex2dec('4F'); 0; 1; 0; 0; 0; 9; 0];
    GEOS_3R_BIN_DataWrite(Bin.data_write, stream);
    
    % �������� ������ 0x44 - ���� ������ (1 ��)
    Bin.data_write(1:8,1)=[hex2dec('44'); 0; 1; 0; 3; 0; 0; 0];
    GEOS_3R_BIN_DataWrite(Bin.data_write, stream);
    
    fopen(stream);
end

StartTime=-1; % ����� ������ ������

while (1)    % �������� ��, � ������� ������ ����� ��������
    for ch=1:phData.NumPointPoiskKA
        % ���������� ������ 16 (0x10) - ������������� ���������� ������� 
        
        [pack0x10, phData.datN] = GEOS_3R_BIN_DataRead(16, stream);
        
        % �������������� ����� "���������� ��"
        phData.NumKA=GEOS_3R_BIN_bin2num(pack0x10(13:16,1), 'int');
        fprintf('NUM KA: %d  \n', phData.NumKA)
        
        for k=1:phData.NumKA      % ��������� ���� ��������� �� ������ 0x10

            % ������ ����, ���������� �� ������� k � ������ 0x10
            rec_ind = 4*(-9+14*k)-3:4*(4+14*k);

            % ��������� ��������� ���� �� �� ������ 0x10
            [phData.tmp_KAnumber        ...   % ����� ��
             phData.tmp_reliable        ...   % ����� �������������
             phData.tmp_SignalToNoise   ...   % q, ����
             phData.tmp_phase           ...   % ����
             phData.tmp_Doppler     ] = ...   % �������� �������
                GEOS_3R_BIN_DataDecod_0x10( pack0x10(rec_ind, 1) );
            
            % ���������� ������� ���������� ������/���
            phData.SNR(ch, phData.tmp_KAnumber) = phData.tmp_SignalToNoise;
        end
        
    end
    
    % ������� ������ �� ����� ������ ��
    [snr, ind_KA] = max(mean(phData.SNR));  % ����� ������������� ��������� �/�
    if(snr > 40)                                      % ��� ���������� ������ ��������� ��������� �/� ������ 40 dBHz
        fprintf('\n OK:  best KA is %d,    SNR = %5.1f dBHz\n', ind_KA, snr)
        break
    else
        fprintf('\n Failed: max SNR = %5.1f dBHz\n', snr)
    end
end
fclose(stream);  % ����� ����������� �� ��������

% ��������� ������ ��� ������
phData.SNR = nan;
phData.SNR(1:phData.NumPoint, 1) = nan;

if (fead_data_from=='GEOS')
    fopen(stream);
else
    stream=fopen(name_bin_file);
end

while (1) % ��������� ������ � ��������� ��
    
    % �������� ������ 0x10 (16) - ������������� ���������� �������
    [pack0x10, phData.datN]=GEOS_3R_BIN_DataRead(hex2dec('10'), stream);
    
    % �������� ������ 0x13 (19) - ������ ��������� ��
    [pack0x13, tmp]=GEOS_3R_BIN_DataRead(hex2dec('13'), stream);
    
    if (length(pack0x13) == 0) || (length(pack0x10) == 0)
        break;  % ������ ���������
    end
    
    % ��������� ��������� 0�10 � 0�13
    fprintf('\n ____________0x10___________')

    % ����� ������ � ������
    ind = 1:phData.NumPoint-1;
    phData.phase(ind, 1)    = phData.phase(ind+1, 1);
    phData.SNR(ind, 1)      = phData.SNR(ind+1, 1);
    phData.reliable(ind, 1) = phData.reliable(ind+1, 1);
    phData.time(ind, 1)     = phData.time(ind+1, 1);
    phData.range(ind, 1)    = phData.range(ind+1, 1);
    phData.ADR(ind, 1)      = phData.ADR(ind+1, 1);
    phData.cycle_d(ind, 1)  = phData.cycle_d(ind+1, 1);
    
    
    % ������� ������ ��� ���������� ��
    n = phData.NumPoint;
    [ phData.UTC,               ...   % ����� UTC � 1 ������ 2008 ���� (����������� ��� ����)
      phData.cycle_d(n, 1),     ...   % ���������� ������ ��� �� ������� ������������� ���������
      phData.kol_vo_KA,         ...   % ���������� �� � ������ 0x10
      phData.SNR(n),            ...   % ��������� ������/���
      phData.phase(n),          ...   % ����
      phData.Doppler,           ...   % �������� �������
      phData.H_liter,           ...   % ?
      phData.range(n),          ...   % ���������������
      phData.ADR(n)         ] = ...   % ������������ ������
        GEOS_3R_BIN_KA_data_0x10( pack0x10,  ind_KA);

    
    if (StartTime<0)                  % ����� ��������� ����� (��� ��������)
        StartTime = phData.UTC;

        if (ind_KA < 65)              % ������� ������� �������
            F_signal = F0_gps;
        else
            F_signal = F0_gln+phData.H_liter*dF_gln;
        end
    end
    
    phData.time(n, 1) = (phData.UTC-StartTime); % �� �� ����������
                                                %            MEAN = mean(phData.cycle_d);
                                                %            ind = find(abs(phData.cycle_d-MEAN)<0.5);
                                                %            phData.mean_Fd=mean(phData.cycle_d(ind));
                                                %            phData.TIME= phData.time+(phData.cycle_d(1,1)-phData.mean_Fd)/phData.mean_Fd;
    
    fprintf('\n UTC (01.01.2008): %9.0f sec', phData.UTC);
    fprintf('\n number KA: %d', phData.kol_vo_KA);
    
    t_gps(1,1) = GEOS_3R_BIN_navi_task_0x13(pack0x13);  % ��������� �������� ������� �� ������ 0x13

    
    % ��������� ������:
    fd = 16.369e6;
    if (sum(~isnan(phData.phase))>3)
        k = find(~isnan(phData.phase));           % ������ ��������, ���������� ���������� ������
        
        apr.phase = phData.phase(k);              % ������� ����
        apr.time = phData.time(k);                % ������� ������ ��������
        
        cycle_d = phData.cycle_d(k);              % ���������� �������� �� ��������� ������������� ��������
        
        apr.phase = apr.phase - cumsum( (cycle_d-16369003) )*98.8540;
        ind = k(1);
        %        apr.phase = phData.range(k)-phData.range(ind) - (phData.phase(k)-phData.phase(ind))./(F0_gps+phData.Doppler/c*F0_gps)*c;
        
        % a = cumsum(cycle_d-16369003);
        % %        ind = find( (cycle_d ~= 16369003) );
        % dcycle = diff(cycle_d);
        % %        dcycle = circshift(dcycle, 2);
        % ind = find( dcycle ~= 0);
        % %        if (length(ind) > 0)% & (ind < length(k)) & (ind > 0)
        % % if (length(ind) > 0) & (min(ind)>0) & (max(ind)<length(k))% & (ind < length(k)) & (ind > 0)
            
        % %     apr.time(ind) = apr.time(ind) - dcycle(ind) * 1/fd*100;
        % %     ind
        % % end
        % % ii = 8;
        % % if (length(k) > ii)
        % %     %            apr.phase(ii)   = apr.phase(ii)   + 98.8540;
        % %     % apr.phase(ii+1) = apr.phase(ii+1) - 98.8540;
        % %     ind
        % % end
        % % apr.phase = apr.phase - a * 97;% 98.8540;

        apr.p2 = polyfit(apr.time, apr.phase, 2);  % ������ ���������� ����������������� ��������
        apr.DataFit = polyval(apr.p2, apr.time);   % ������ �������������
        
        apr.DataPhase2=(apr.phase-apr.DataFit);    % ������� �������� ���� � �������������
        
        tmp=0;
        m=0;
        for(k=1:length(apr.DataPhase2))
            if(isnan(apr.DataPhase2)==0)
                tmp=tmp+apr.DataPhase2(k);
                m=m+1;
            end
        end
        apr.sredn(1:length(apr.DataPhase2))=tmp/m;
    else
        apr.DataPhase2=nan;
        apr.DataFit=nan;
        apr.phase=nan;
        apr.time=nan;
        apr.aprTime=nan;
        apr.aprDataPhase2=nan;
        apr.sredn=nan;
    end       
    
    %����� ��������:
    figure(1);
    
    subplot(2,2,1)
    plot(phData.time, phData.cycle_d,'r')
    grid on
    xlabel('time, sec');
    ylabel('phase, cycles');
    
    subplot(2,2,2)
    plot(phData.time, phData.SNR)
    grid on
    xlabel('time, sec');
    ylabel('signal to noise, dBHz');
    
    subplot(2,2,3)
    plot(apr.time,apr.DataPhase2,'b')
    grid on
    xlabel('time, sec');
    ylabel('d phase, cycles');
    
    subplot(2,2,4)
    %    plot(phData.time, phData.phase, 'b', apr.time, apr.DataFit,'r')
    plot(apr.time, apr.phase, 'b', apr.time, apr.DataFit,'r')
    grid on
    xlabel('time, sec');
    ylabel('d phase, ');
    drawnow
    %    end
    
    ind = min(find(~isnan(phData.range)));
    figure(2);
    % hold off
    % plot(phData.time, phData.range-phData.range(ind), 'b');
    % grid on
    
    % hold on
    % plot(phData.time, (phData.phase-phData.phase(ind))./(F0_gps+phData.Doppler/c*F0_gps)*c, 'r');
    % grid on

    hold off
    plot(phData.time, phData.range-phData.range(ind) - (phData.phase-phData.phase(ind))./(F0_gps+phData.Doppler/c*F0_gps)*c, 'r');
    grid on
    hold on
    
    plot(phData.time, (phData.ADR-phData.ADR(ind))*F0_gps/c*2, 'k');
    grid on

    hold off
end








