function [ res ] = Geos3_decode_packet(data)
    
% Описание структуры пакета 0x10
    Geos3PS = {'pack0x10'
               { 'tGEOS',      'double',       (1-1)*4;
                 'MeasCycles', 'int32',        (3-1)*4;
                 'NSat',       'int32',        (4-1)*4;
                 'SatMeas',    'struct[NSat]', (5-1)*4;
               };
               'SatMeas'
               { 'Flags',      'uint8',     1-1;
                 'Lit',        'int8',      2-1;
                 'satID',      'uint8',     3-1;
                 'NChnl',      'uint8',     4-1;
                 
                 'q',          'float',  ( 2-1)*4;
                 'PR',         'double', ( 3-1)*4;
                 'PV',         'double', ( 5-1)*4;
                 'ADR',        'double', ( 7-1)*4;
                 'PH',         'double', ( 9-1)*4;
                 'stdPR',      'float',  (11-1)*4;
                 'stdPV',      'float',  (12-1)*4;
                 'errPR',      'float',  (13-1)*4;
                 'errPV',      'float',  (14-1)*4;
                 }};
    
    Types = {'double', 8;
             'float',  4;
             'int8',   1;
             'uint8',  1;
             'int16',  2;
             'uint16', 2;
             'int32',  4;
             'uint32', 4
             };
    
    cmd = hex2dec('10');
    pack = [];
    for i=1:2:size(Geos3PS, 1)
        sprintf('pack0x%02X', cmd)
        if strcmp(sprintf('pack0x%02X', cmd), Geos3PS{i, 1})
            pack = Geos3PS{i+1, 1};
        end
    end
    
    global res
    res = [];

    for i=1:size(pack, 1)
        field = char(pack{i, 1});
        type  = char(pack{i, 2});
        pos   = pack{i, 3};

        if (isempty(regexp(type, 'struct')))
            for t=1:size(Types, 1)
                if strcmp(type, Types{t, 1})
                    num1 = GEOS_3R_BIN_bin2num(data( pos+1 + (0:Types{t, 2}-1)), type);
                    num2 = bin2num(data( pos+1 + (0:Types{t, 2}-1)), type);
                    [num1 num2]
                    res.(field) = num1;
                    break;
                end
            end
        else
            t = regexp(type, 'struct\[(\w*)\]', 'tokens');
            if length(t)>0
                t = char(t{1});
                fprintf('t: |%s|\n', t);
                try, res.(t)
                catch
                    fprintf('Unknown field: %s\n', type);
                    break;
                end
                
                Strt = [];
                for k=1:2:size(Geos3PS, 1)
                    if strcmp(field, Geos3PS{k, 1})
                        Strt = Geos3PS{k+1, 1};
                    end
                end

                StructSize = 0;
                for fl=1:size(Strt, 1)
                    tp  = Strt{fl, 2};
                    for tt=1:size(Types, 1)
                        if strcmp(tp, Types{tt, 1})
                            StructSize = StructSize + Types{tt, 2};
                        end
                    end
                end

                for j=1:res.(t)
                    fprintf('Strt %d\n', j);
                    for fl=1:size(Strt, 1)
                        fld = Strt{fl, 1};
                        tp  = Strt{fl, 2};
                        ps  = (j-1)*StructSize + Strt{fl, 3};
                        fprintf('   posit: %d ', pos+1+ps);
                        for tt=1:size(Types, 1)
                            if strcmp(tp, Types{tt, 1})
                                
                                fprintf('field %s  type %s  ', fld, tp);
                        
                                num = bin2num(data( pos+1+ps + (0:Types{tt, 2}-1)), tp);
                                break
                            end
                        end
                        fprintf('val: %g\n', num);

                        
                    end
                end
            end
        end
    end
    
    length(data)
    
    res
    
% %UNTITLED2 Summary of this function goes here
% %   Detailed explanation goes here
% UTC = GEOS_3R_BIN_bin2num(data(1:8),'double');
% cycle_d = data(9)+data(10)*2^8+data(11)*2^16+data(12)*2^24;
% kol_vo_KA = data(13)+data(14)*2^8+data(15)*2^16+data(15)*2^24;

% ind=0;
% for(k=1:kol_vo_KA)
%     if(data(4*(-9+14*k)-1)==KAnumber)
%         ind=k;
%         break
%     end
% end

% if(ind>0)
%     SignalToNoise = GEOS_3R_BIN_bin2num(data(4*(-8+14*ind)-3 : 4*(-8+14*ind)),'float');
%     phase         = GEOS_3R_BIN_bin2num(data(4*(-1+14*ind)-3 : 4*( 0+14*ind)),'double');
%     Doppler       = GEOS_3R_BIN_bin2num(data(4*(-5+14*ind)-3 : 4*(-4+14*ind)),'double');
%     Range         = GEOS_3R_BIN_bin2num(data(4*(-7+14*ind)-3 : 4*(-6+14*ind)),'double');
%     ADR           = GEOS_3R_BIN_bin2num(data(4*(-3+14*ind)-3 : 4*(-2+14*ind)),'double');
%     H_liter       = mod(data(4*(-9+14*ind)-2),2^7)*(-1)^(fix(data(4*(-9+14*ind)-2)/2^7));
%     type          = GEOS_3R_BIN_bin2num(data(4*(-9+4+14*ind) + (-3:0)) , 'int') ;
% else
%     SignalToNoise = nan;
%     phase         = nan;
%     Doppler       = nan;
%     Range         = nan;
%     ADR           = nan;
%     H_liter       = nan;
%     type = nan;
% end
% end

