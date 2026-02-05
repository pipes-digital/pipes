
class Duplicateblock < Block
    def process(inputs)
        return inputs[0]
    end

end

class WateredDuplicateblock < WateredBlock
    def process(inputs)
        return inputs[0]
    end

end