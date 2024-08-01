function [closestPair, remainingPairs] = selectByDifficulty(food_pairs, desiredDifficulty)
    % Calculate the absolute difference of each pair's difficulty from the desired level
    difficulties = abs([food_pairs{:, 7}] - desiredDifficulty);
    
    % Find the index of the pair with the minimum difference
    [~, closestIndex] = min(difficulties);
    
    % Extract the closest pair
    closestPair = food_pairs(closestIndex, :);
    
    % Remove the closest pair from the original array to get the remaining pairs
    remainingPairs = food_pairs;
    remainingPairs(closestIndex, :) = [];
end

