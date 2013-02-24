#
# support: CRuby & mruby
#

module Enumerable
    def map_with_index(&block)
        i = 0
        self.map { |val|
            val = block.call(val, i)
            i += 1
            val
        }
    end

    def select_with_index(&block)
        i = 0
        self.select { |val|
            val = block.call(val, i)
            i += 1
            val
        }
    end
end


class Stage
    attr_reader :width, :height

    def initialize(width, height)
        @width, @height = width, height
        @items = (1..@width).map{(1..@height).map{Hash.new}}
    end

    def [](x, y)
        return {} if x < 0 || x >= @items.size || y < 0 || y >= @items[x].size 
        @items[x][y] || {}
    end

    def []=(x, y, item)
        return {} if x < 0 || x >= @items.size || y < 0 || y >= @items[x].size 
        @items[x][y] = item
    end

    def each(&block)
        @items.each_with_index do |line, x|
            line.each_with_index do |item, y|
                block.call(@items[x][y], x, y) if item        
            end
        end
        self
    end
    
    def check(x, y, checked=[], &block)
        return checked if checked.include?([x, y])

        item = self[x, y]
        return checked unless item[:color]

        checked << [x, y]
        item_color = item[:color]
        block.call(item, x, y) if block

        checked = check(x - 1, y, checked, &block) if self[x - 1, y][:color] == item_color
        checked = check(x + 1, y, checked, &block) if self[x + 1, y][:color] == item_color
        checked = check(x, y - 1, checked, &block) if self[x, y - 1][:color] == item_color
        checked = check(x, y + 1, checked, &block) if self[x, y + 1][:color] == item_color

        checked
    end

    def remove(x, y, &block)
        removed = []
        check(x, y) do |item, xx, yy|
            block.call(item, xx, yy) if block
            self[xx, yy][:color] = nil
            removed << [self[xx, yy], xx, yy]
        end
        removed
    end

    def fall(&block)
        @items = @items.map_with_index do |line, x|
            steps = 0
            line.select_with_index do |item, y|
                if item[:color]
                    block.call(item, x, y, steps) if steps > 0 && block
                    true
                else
                    steps += 1
                    false
                end
            end
        end
    end

    def compact(&block)
        step = 0
        @items = @items.select_with_index do |line, x|
            if line.size == 0
                step += 1
                false
            else
                block.call(x, step) if step > 0 && block
                true
            end
        end
    end

    def is_cleared?
        @items.size == 0
    end

    def is_gameover?
        @items.map_with_index do |line, x|
            line.select_with_index do |item, y|
                item_color = item[:color]
                if item_color
                    return false if self[x - 1, y][:color] == item_color
                    return false if self[x + 1, y][:color] == item_color
                    return false if self[x, y - 1][:color] == item_color
                    return false if self[x, y + 1][:color] == item_color
                end
            end
        end
        return true
    end
end



class Stage
    def to_s
        str = ''
        @height.times do |y|
            @width.times do |x|
                c = self[x, @height - y - 1][:color]
                str += c ? c.to_s[0,1] : ' '
            end
            str += "\n"
        end
        str
    end
end


if false
$score = 0
def click(stage, x, y)
    puts ">" * 15
    puts stage
    puts "-" * 5
    puts
    puts "Remove: (0,0)"
    removed = stage.remove(x, y) do |item, x, y|
        print '  '
        p [x, y, item]
    end
    $score += (removed.size - 2) ** 2

    puts stage
    puts "-" * 5
    puts
    puts "Fall:"
    stage.fall do |item, x, y, step|
        print '  '
        p [item, x, y, step]
    end
    puts stage
    puts "-" * 5
    puts 
    puts "Compact:"
    stage.compact do |x, steps|
        print '  '
        p [x, steps]
    end
    puts stage
    puts "-" * 5
    puts "Score: #{$score}"
    puts 
    if stage.is_cleared?
        puts "Congrats!"
        puts 
    elsif stage.is_gameover?
        puts "Game over!"
        puts 
    end
end

stage = Stage.new(5,4)

["XLX..",
 "XLXXX",
 "XL..X",
 "XL..X"].each_with_index do |line, y|
    line.length.times do |x|
        stage[x, y][:color] = line[x, 1]
    end
end

click(stage, 1, 0)
click(stage, 2, 0)
click(stage, 0, 3)
click(stage, 0, 0)

end
