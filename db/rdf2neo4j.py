def prep_vertex_all():
    ferror = open("err_vertex.csv",'w')
    frname = "vertex.csv"
    fwname = "vertex_output_all.csv"
    with open(frname, 'r') as fr:
        with open(fwname, 'w') as fw:
            fw.write("{},{},{}\n".format(":ID", "name", ":LABEL"))
            for line in fr:
                try:
                    # print(line.strip())
                    line = line.strip()
                    if not line:
                        continue
                    spo = line.split(",")
                    # print(spo)
                    fw.write("{},{},{}\n".format(spo[0].replace('"',''), spo[1].replace('"',''), "ENTITY"))
                except:
                    ferror.write("{}\n".format(line))
                    continue
 
def prep_edge_all():
    ferror = open("err_edge.csv",'w')
    frname = "edge.csv"
    fwname = "edge_output_all.csv"
    print(frname)
    print(fwname)
    with open(frname, 'r') as fr:
        with open(fwname, 'w') as fw:
            fw.write("{},{},{},{}\n".format(":START_ID", "name", ":END_ID", ":TYPE"))
            for line in fr:
                try:
                    # print(line.strip())
                    line = line.strip()
                    if not line:
                        continue
                    spo = line.split(",")
                    # print(spo)
                    fw.write("{},{},{},{}\n".format(spo[0].replace('"',''), spo[2].replace('"', ''), spo[1].replace('"',''), "RELATIONSHIP"))
                except:
                    ferror.write("{}\n".format(line))
                    continue
 
 
if __name__ == '__main__':
    prep_vertex_all()
    prep_edge_all()