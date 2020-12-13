package com.liu.pojo;

/**
 * @author root
 * @create 2020-11-13 14:43
 */
public class news {
    private String title;
    private String newsContent;
    private String creator;
    private String createDate;

    public news() {
    }

    public news(String title, String newsContent, String creator, String createDate) {
        this.title = title;
        this.newsContent = newsContent;
        this.creator = creator;
        this.createDate = createDate;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getNewsContent() {
        return newsContent;
    }

    public void setNewsContent(String newsContent) {
        this.newsContent = newsContent;
    }

    public String getCreator() {
        return creator;
    }

    public void setCreator(String creator) {
        this.creator = creator;
    }

    public String getCreateDate() {
        return createDate;
    }

    public void setCreateDate(String createDate) {
        this.createDate = createDate;
    }

    @Override
    public String toString() {
        return "news{" +
                "title='" + title + '\'' +
                ", newsContent='" + newsContent + '\'' +
                ", creator='" + creator + '\'' +
                ", createDate='" + createDate + '\'' +
                '}';
    }
}
