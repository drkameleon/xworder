#!/usr/bin/env ruby

require 'awesome_print'

words = File.read(ARGV[0]).split("\n").map{|w| w.strip.upcase}

$wordlist = words # words.sort_by{|x| x.length}.reverse

$grid_dimension = ARGV[1].to_i

def placeWord(word,x,y,horizontal=true,grid=$grid)
	grid_x = x
	grid_y = y
	word.split("").each_with_index{|c,i|
		grid[grid_x][grid_y] = c.upcase

		horizontal ? grid_x += 1 : grid_y += 1
	}
end

def placeable(word,x,y,horizontal=true,grid=$grid)

	dimension = grid.count

	intersections = 0

	if horizontal
		if x+word.length>dimension
			return false
		end
	else
		if y+word.length>dimension
			return false
		end
	end

	grid_x = x
	grid_y = y

	if horizontal and grid_x-1>=0 and !grid[grid_x-1][grid_y].nil?
		return false
	end
	if !horizontal and grid_y-1>=0 and !grid[grid_x][grid_y-1].nil?
		return false
	end

	forgive_col = -1
	forgive_row = -1

	word.split("").each_with_index{|c,i|
		if !grid[grid_x][grid_y].nil? and grid[grid_x][grid_y] != c.upcase
			return false
		end

		if !grid[grid_x][grid_y].nil? and grid[grid_x][grid_y] == c.upcase
			if horizontal
				forgive_col = grid_x
			else
				forgive_row = grid_y
			end
			intersections += 1
		end

		begin
			if horizontal

				if grid_x!=forgive_col and (!grid[grid_x][grid_y-1].nil? or !grid[grid_x][grid_y+1].nil?)
					return false
				end
			else
				if grid_y!=forgive_row and (!grid[grid_x-1][grid_y].nil? or !grid[grid_x+1][grid_y].nil?)
					return false
				end
			end
		rescue
		end

		horizontal ? grid_x += 1 : grid_y += 1
	}

	if (grid_x<dimension and grid_y<dimension) and !grid[grid_x][grid_y].nil?
		return false
	end

	return intersections
end

def printGrid(grid=$grid)
	(0...grid.size).each{|row|
		(0...grid.size).each{|col|
			if grid[col][row].nil?
				printf "  "
			else
				printf grid[col][row] + " "
			end
		}
		printf "\n"
	}
end

def printGridLatex(grid=$grid)
	output = ""
	output += "\\begin{Puzzle}{#{grid.size}}{#{grid.size}}\n"
	(0...grid.size).each{|row|
		output += "\t"
		(0...grid.size).each{|col|
			if grid[col][row].nil?
				output += "|{}\t" #"|{}\t"
			else
				gNFC = getNumberForCell(col,row)

				if !gNFC
					gNFC=""
				else
					gNFC="[#{gNFC}]"
				end
				output += "|#{gNFC}#{grid[col][row]}\t"
			end
		}
		output += "|.\n"
	}
	output += "\\end{Puzzle}\n"
	return output
end

$clues_hori = []
$clues_vert = []

def getRandomGrid
	begin
		$clues_hori = []
		$clues_vert = []
		$clues_index = 1

		$grid = Array.new($grid_dimension){Array.new($grid_dimension)}

		$wordlist.each_with_index{|word,i|
			placeables = {}
			(0...$grid_dimension).each{|row|
				(0...$grid_dimension).each{|col|
					placeables["#{col},#{row},h"] = placeable(word,col,row,horizontal=true,grid=$grid)
					placeables["#{col},#{row},v"] = placeable(word,col,row,horizontal=false,grid=$grid)
				}
			}

			placeables = placeables.select{|k,v| v!=false}.sort_by {|k,v| v}.to_h

			inter_placeables = placeables.select{|k,v| v>= 1 }.sort_by {|k,v| v}.to_h
			if inter_placeables.count == 0
				rkey = placeables.keys[rand(0...placeables.size)]
				final_placement = rkey

				if i!=0
					return false
				end
			else
				rkey = inter_placeables.keys[rand(0...inter_placeables.size)]
				final_placement = rkey
			end

			parts = rkey.scan /(\d+),(\d+),([hv])/
			parts_col = parts[0][0].to_i
			parts_row = parts[0][1].to_i
			if parts[0][2].to_s=="h"
				parts_horiz = true
			else
				parts_horiz = false
			end

			#puts "Placing word: #{word} @ #{parts_col},#{parts_row} (#{parts[0][2]}) - #{inter_placeables}"
			placeWord(word,parts_col,parts_row,parts_horiz,$grid)

			if parts_horiz
				$clues_hori << {
					"x" => parts_col,
					"y" => parts_row,
					"w" => word,
					"i" => $clues_index
				}
			else
				$clues_vert << {
					"x" => parts_col,
					"y" => parts_row,
					"w" => word,
					"i" => $clues_index

				}
			end
			$clues_index += 1

		}
		return $grid
	rescue
		return false
	end
end

def getNumberForCell(col,row)
	$clues_hori.each_with_index{|cl,c|
		if cl["x"]==col and cl["y"]==row
			return cl["i"]
		end
	}

	$clues_vert.each_with_index{|cl,c|
		if cl["x"]==col and cl["y"]==row
			return cl["i"]
		end
	}

	return false
end

def verifyGrid(grid)
	begin
		(0...grid.size).each{|row|
			(0...grid.size).each{|col|
				if !grid[col][row].nil? and !grid[col+1][row].nil? and !grid[col+1][row+1].nil? and !grid[col][row+1].nil?
					return false
				end
			}
		}
	rescue
	end

	return true
end

ok = false
tries = 0

while !ok
	new_grid = getRandomGrid
	tries += 1
	if new_grid!=false and verifyGrid(new_grid)
		ok = true
	end
	if tries > 1000
		break
	end
end

if ok
	puts "--" * $grid_dimension
	printGrid(new_grid)
	puts "--" * $grid_dimension
else
	puts "FAILED"
end
puts "After: #{tries} tries"

clues_hori_txt = ""
$clues_hori.each{|cl|
	clues_hori_txt += "\\Clue{#{cl["i"]}}{#{cl["w"]}}{#{cl["w"]}}\n"
}

clues_vert_txt = ""
$clues_vert.each{|cl|
	clues_vert_txt += "\\Clue{#{cl["i"]}}{#{cl["w"]}}{#{cl["w"]}}\n"
}

template = File.read("cross_template.tex").gsub("%PUZZLE%",printGridLatex(new_grid))
										  .gsub("\%CLUES_HORI%",clues_hori_txt)
										  .gsub("\%CLUES_VERT%",clues_vert_txt)

File.open("output.tex","w"){|f|
	f.write(template)
}

system("xelatex output.tex")
