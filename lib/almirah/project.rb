require_relative "doc_items/doc_item"
require_relative "specification"
require_relative "html_render"

class Project

    attr_accessor :specifications
    attr_accessor :project_root_directory
    attr_accessor :gem_root

    def initialize(path, gem_root)
        @project_root_directory = path
        @specifications = Array.new
        @gem_root = gem_root

        parse_all_documents()
        link_all_specifications()
        render_all_specifications()
       
    end

    def parse_all_documents
        
        Dir.glob( "#{@project_root_directory}/**/*.md" ).each do |f|
            puts f
            spec = Specification.new(f)
            @specifications.append(spec)
        end
    end

    def link_all_specifications
        combList = @specifications.combination(2)
        combList.each do |c|
            self.link_two_specifications(c[0], c[1])
        end
    end

    def link_two_specifications(doc_A, doc_B)

        if doc_A.key == doc_B.up_link_key
            top_document = doc_A
            bottom_document = doc_B
        elsif doc_B.key == doc_A.up_link_key
            top_document = doc_B
            bottom_document = doc_A
        else
            puts "No Links"
            return # no links
        end

        bottom_document.controlledParagraphs.each do |item|

            if top_document.dictionary.has_key?(item.up_link.to_s)

                topItem = top_document.dictionary[item.up_link.to_s]
                
                unless topItem.down_links
                    topItem.down_links = Array.new
                end
                topItem.down_links.append(item)

                #if tmp = /^([a-zA-Z]+)[-]\d+/.match(item.id)
                #    top_document.downlinkKey = tmp[1].upcase
                #end
            end
        end
    end

    def render_all_specifications
        
        pass = @project_root_directory

        FileUtils.remove_dir(pass + "/build", true)
        FileUtils.mkdir_p(pass + "/build/specifications")
    
        @specifications.each do |spec|

            img_src_dir = pass + "/specifications/" + spec.key.downcase + "/img"
            img_dst_dir = pass + "/build/specifications/" + spec.key.downcase + "/img"
     
            FileUtils.mkdir_p(img_dst_dir)

            if File.directory?(img_src_dir)
                FileUtils.copy_entry( img_src_dir, img_dst_dir )
            end

            HtmlRender.new( spec,
            @gem_root + "/lib/almirah/templates/page.html",
            "#{pass}/build/specifications/#{spec.key.downcase}/#{spec.key.downcase}.html" )
        end
    end
end