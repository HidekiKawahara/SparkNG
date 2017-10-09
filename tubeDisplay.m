function crossSection = tubeDisplay(logArea)
%%
areaList = exp(logArea);
crossSection = sqrt(areaList/sum(areaList));

%%
end