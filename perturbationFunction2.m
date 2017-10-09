function perturbationOut = perturbationFunction2(perturbation)
persistent stateMem;
if ~(length(stateMem) == 0)
    stateMem = stateMem+1;
else
    stateMem = 1;
end;    
switch perturbation
    case 'gaussian'
        perturbationOut = randn;
    case 'P0MRandom'
        perturbationOut = round((rand-0.5)*2.9999);
    case 'Alteration'
        if rem(stateMem,2) == 0
            perturbationOut = 1;
        else
            perturbationOut = -1;
        end;
end;
end
