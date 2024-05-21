import numpy
import wtf

a = wtf.WTF()

features = {}

for i in range(100):
    features[f'F{i}'] = numpy.random.rand(100)
    print(a.calculate(features))

