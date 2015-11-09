SparkleFormation.new('traversal') do
  nest1.nest2.nest3.nest4.nest5.root!.test1 'test1'

  a1 do
    a2 do
      a3 do
        root!.test2 'test2'
      end
    end
  end

  nest1.nest2.nest3.nest4.parent!.test3 'test3'

end
